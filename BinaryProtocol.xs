#include "binary_protocol.h"

MODULE = Thrift::XS   PACKAGE = Thrift::XS::BinaryProtocol

void
writeMessageBegin(SV *self, SV *name, int type, int seqid)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *namecopy = sv_mortalcopy(name); // because we can't modify the original name
  sv_utf8_encode(namecopy);
  int namelen = sv_len(namecopy);
  SV *data = sv_2mortal(newSV(8 + namelen));
  char i32[4];
  
  // i32 type
  type = VERSION_1 | type;
  INT_TO_I32(i32, type, 0);
  sv_setpvn(data, i32, 4);
  
  // i32 len + string
  INT_TO_I32(i32, namelen, 0);
  sv_catpvn(data, i32, 4);
  sv_catsv(data, namecopy);
  
  // i32 seqid
  INT_TO_I32(i32, seqid, 0);
  sv_catpvn(data, i32, 4);
  
  WRITE_SV(trans, data);
}

void
writeMessageEnd(SV *)
CODE:
{ }

void
writeStructBegin(SV *, SV *)
CODE:
{ }

void
writeStructEnd(SV *)
CODE:
{ }

void
writeFieldBegin(SV *self, SV * /*name*/, int type, int id)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[3];
  
  data[0] = type & 0xff;      // byte
  data[1] = (id >> 8) & 0xff; // i16
  data[2] = id & 0xff;
  
  WRITE(trans, data, 3);
}

void
writeFieldEnd(SV *)
CODE:
{ }

void
writeFieldStop(SV *self)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[1];
  data[0] = T_STOP;
  
  WRITE(trans, data, 1);
}

void
writeMapBegin(SV *self, int keytype, int valtype, int size)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[6];
  
  data[0] = keytype & 0xff;
  data[1] = valtype & 0xff;
  INT_TO_I32(data, size, 2);

  WRITE(trans, data, 6);
}

void
writeMapEnd(SV *)
CODE:
{ }

void
writeListBegin(SV *self, int elemtype, int size)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[5];
  
  data[0] = elemtype & 0xff;
  INT_TO_I32(data, size, 1);
  
  WRITE(trans, data, 5);
}

void
writeListEnd(SV *)
CODE:
{ }

void
writeSetBegin(SV *self, int elemtype, int size)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[5];
  
  data[0] = elemtype & 0xff;
  INT_TO_I32(data, size, 1);
  
  WRITE(trans, data, 5);
}

void
writeSetEnd(SV *)
CODE:
{ }

void
writeBool(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[1];
  
  data[0] = SvOK(value) ? 1 : 0;
  
  WRITE(trans, data, 1);
}

void
writeByte(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[1];
  
  data[0] = SvIV(value) & 0xff;
  
  WRITE(trans, data, 1);
}

void
writeI16(SV *self, int value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[2];
  
  data[0] = (value >> 8) & 0xff;
  data[1] = value & 0xff;
  
  WRITE(trans, data, 2);
}

void
writeI32(SV *self, int value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[4];
  
  INT_TO_I32(data, value, 0);
  
  WRITE(trans, data, 4);
}

void
writeI64(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[8];
  int64_t i64 = (int64_t)SvNV(value);
  
  data[7] = i64 & 0xff;
  data[6] = (i64 >> 8) & 0xff;
  data[5] = (i64 >> 16) & 0xff;
  data[4] = (i64 >> 24) & 0xff;
  data[3] = (i64 >> 32) & 0xff;
  data[2] = (i64 >> 40) & 0xff;
  data[1] = (i64 >> 48) & 0xff;
  data[0] = (i64 >> 56) & 0xff;
  
  WRITE(trans, data, 8);
}

void
writeDouble(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[8];
  union {
    double d;
    int64_t i;
  } u;
  
  u.d = (double)SvNV(value);

  data[7] = u.i & 0xff;
  data[6] = (u.i >> 8) & 0xff;
  data[5] = (u.i >> 16) & 0xff;
  data[4] = (u.i >> 24) & 0xff;
  data[3] = (u.i >> 32) & 0xff;
  data[2] = (u.i >> 40) & 0xff;
  data[1] = (u.i >> 48) & 0xff;
  data[0] = (u.i >> 56) & 0xff;
  
  WRITE(trans, data, 8);
}

void
writeString(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *valuecopy = sv_mortalcopy(value);
  sv_utf8_encode(valuecopy);
  int len = sv_len(valuecopy);
  SV *data = sv_2mortal(newSV(4 + len));
  char i32[4];
  
  INT_TO_I32(i32, len, 0);
  sv_setpvn(data, i32, 4);
  sv_catsv(data, valuecopy);
  
  WRITE_SV(trans, data);
}

void
readMessageBegin(SV *self, SV *name, SV *type, SV *seqid)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  int version;
  char *tmps;
  
  // read version + type
  READ_SV(trans, tmp, 4);
  tmps = SvPVX(tmp);
  I32_TO_INT(version, tmps, 0);
  
  if (version < 0) {
    if ((version & VERSION_MASK) != VERSION_1) {
      THROW("Thrift::TException", "Missing version identifier");
    }
    // set type
    if (SvROK(type))
      sv_setiv(SvRV(type), version & 0x000000ff);
    
    // read string
    {
      int len;
      READ_SV(trans, tmp, 4);
      tmps = SvPVX(tmp);
      I32_TO_INT(len, tmps, 0);
      if (len) {
        READ_SV(trans, tmp, len);
        sv_utf8_decode(tmp);
        if (SvROK(name))
          sv_setsv(SvRV(name), tmp);
      }
      else {
        if (SvROK(name))
          sv_setpv(SvRV(name), "");
      }
    }
    
    // read seqid
    {
      int s;
      READ_SV(trans, tmp, 4);
      tmps = SvPVX(tmp);
      I32_TO_INT(s, tmps, 0);
      if (SvROK(seqid))
        sv_setiv(SvRV(seqid), s);
    }
  }
  else {
    THROW("Thrift::TException", "Missing version identifier");
  }
}

void
readMessageEnd(SV *)
CODE:
{ }

void
readStructBegin(SV *, SV *name)
CODE:
{
  if (SvROK(name))
    sv_setpv(SvRV(name), "");
}

void
readStructEnd(SV *)
CODE:
{ }

void
readFieldBegin(SV *self, SV * /*name*/, SV *fieldtype, SV *fieldid)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 3);
  tmps = SvPVX(tmp);
  
  // fieldtype byte
  if (SvROK(fieldtype))
    sv_setiv(SvRV(fieldtype), tmps[0]);
  
  if (tmps[0] == T_STOP) {
    if (SvROK(fieldid))
      sv_setiv(SvRV(fieldid), 0);
    XSRETURN_EMPTY;
  }
  
  // fieldid i16
  int fid;
  I16_TO_INT(fid, tmps, 1);
  if (SvROK(fieldid))
    sv_setiv(SvRV(fieldid), fid);
}

void
readFieldEnd(SV *)
CODE:
{ }

void
readMapBegin(SV *self, SV *keytype, SV *valtype, SV *size)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 6);
  tmps = SvPVX(tmp);
  
  // keytype byte
  if (SvROK(keytype))
    sv_setiv(SvRV(keytype), tmps[0]);
  
  // valtype byte
  if (SvROK(valtype))
    sv_setiv(SvRV(valtype), tmps[1]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 2);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}

void
readMapEnd(SV *)
CODE:
{ }

void
readListBegin(SV *self, SV *elemtype, SV *size)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 5);
  tmps = SvPVX(tmp);
  
  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), tmps[0]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 1);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}

void
readListEnd(SV *)
CODE:
{ }

void
readSetBegin(SV *self, SV *elemtype, SV *size)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 5);
  tmps = SvPVX(tmp);
  
  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), tmps[0]);
  
  // size i32
  int isize;
  I32_TO_INT(isize, tmps, 1);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
}

void
readSetEnd(SV *)
CODE:
{ }

void
readBool(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 1);
  tmps = SvPVX(tmp);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), tmps[0] ? 1 : 0);
}

void
readByte(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 1);
  tmps = SvPVX(tmp);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), tmps[0]);
}

void
readI16(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 2);
  tmps = SvPVX(tmp);
  
  int v;
  I16_TO_INT(v, tmps, 0);
  if (SvROK(value))
    sv_setiv(SvRV(value), v);
}

void
readI32(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 4);
  tmps = SvPVX(tmp);
  
  int v;
  I32_TO_INT(v, tmps, 0);
  if (SvROK(value))
    sv_setiv(SvRV(value), v);
}

void
readI64(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 8);
  tmps = SvPVX(tmp);
  
  uint64_t hi;
  uint32_t lo;
  I32_TO_INT(hi, tmps, 0);
  I32_TO_INT(lo, tmps, 4);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), (hi << 32) | lo);
}

void
readDouble(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  READ_SV(trans, tmp, 8);
  tmps = SvPVX(tmp);
  
  uint64_t hi;
  uint32_t lo;
  I32_TO_INT(hi, tmps, 0);
  I32_TO_INT(lo, tmps, 4);

  union {
    double d;
    int64_t i;
  } u;  
  u.i = (hi << 32) | lo;
  
  if (SvROK(value))
    sv_setnv(SvRV(value), u.d);
}

void
readString(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  int len;
  READ_SV(trans, tmp, 4);
  tmps = SvPVX(tmp);
  I32_TO_INT(len, tmps, 0);
  if (len) {
    READ_SV(trans, tmp, len);
    sv_utf8_decode(tmp);
    if (SvROK(value))
      sv_setsv(SvRV(value), tmp);
  }
  else {
    if (SvROK(value))
      sv_setpv(SvRV(value), "");
  }
}

void
readStringBody(SV *self, SV *value, int len)
CODE:
{
  // This method is never used but is here for compat
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  
  if (len) {
    READ_SV(trans, tmp, len);
    sv_utf8_decode(tmp);
    if (SvROK(value))
      sv_setsv(SvRV(value), tmp);
  }
  else {
    if (SvROK(value))
      sv_setpv(SvRV(value), "");
  }
}
