MODULE = Thrift::XS   PACKAGE = Thrift::XS::CompactProtocol

void
writeMessageBegin(SV *self, SV *name, int type, uint32_t seqid)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *namecopy = sv_mortalcopy(name); // because we can't modify the original name
  sv_utf8_encode(namecopy);
  uint32_t namelen = sv_len(namecopy);
  SV *data = sv_2mortal(newSV(16 + namelen));
  char tmp[5]; // 5 required for varint32
  
  // byte protocol ID
  tmp[0] = PROTOCOL_ID;
  
  // byte version/type
  tmp[1] = (VERSION_N & VERSION_MASK_COMPACT) | ((type << TYPE_SHIFT_AMOUNT) & TYPE_MASK);
  
  sv_setpvn(data, tmp, 2);
  
  // varint32 seqid
  int varlen;
  UINT_TO_VARINT(varlen, tmp, seqid, 0);
  sv_catpvn(data, tmp, varlen);

  // varint32 len + string
  UINT_TO_VARINT(varlen, tmp, namelen, 0);
  sv_catpvn(data, tmp, varlen);
  sv_catsv(data, namecopy);

  WRITE_SV(trans, data);
}

void
writeMessageEnd(SV *)
CODE:
{ }

void
writeStructBegin(SV *self, SV *)
CODE:
{
  // No writing here, but we push last_field_id onto the fields stack
  HV *selfh = (HV *)SvRV(self);
  
  SV *last_field_id = my_hv_delete(selfh, "last_field_id");
  AV *last_fields = (AV *)SvRV(*(my_hv_fetch(selfh, "last_fields")));
  av_push(last_fields, newSVsv(last_field_id));
  
  my_hv_store(selfh, "last_field_id", newSViv(0));
}

void
writeStructEnd(SV *self)
CODE:
{
  // pop last field off the stack
  HV *selfh = (HV *)SvRV(self);
  AV *last_fields = (AV *)SvRV(*(my_hv_fetch(selfh, "last_fields")));
  my_hv_store(selfh, "last_field_id", av_pop(last_fields));
}

void
writeFieldBegin(SV *self, SV * /*name*/, int type, int id)
CODE:
{
  if (unlikely(type == T_BOOL)) {
    // Special case, save type/id for use later
    HV *selfh = (HV *)SvRV(self);
    my_hv_store(selfh, "bool_type", newSViv(type));
    my_hv_store(selfh, "bool_id", newSViv(id));
  }
  else {
    write_field_begin_internal(self, type, id, -1);
  }
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
writeMapBegin(SV *self, int keytype, int valtype, uint32_t size)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[6];
  
  if (size == 0) {
    data[0] = 0;
    WRITE(trans, data, 1);
  }
  else {
    int varlen;
    UINT_TO_VARINT(varlen, data, size, 0);
    data[varlen] = (get_compact_type(keytype) << 4) | get_compact_type(valtype);
    WRITE(trans, data, varlen + 1);
  }
}

void
writeMapEnd(SV *)
CODE:
{ }

void
writeListBegin(SV *self, int elemtype, int size)
CODE:
{
  write_collection_begin_internal(self, elemtype, size);
}

void
writeListEnd(SV *)
CODE:
{ }

void
writeSetBegin(SV *self, int elemtype, int size)
CODE:
{
  write_collection_begin_internal(self, elemtype, size);
}

void
writeSetEnd(SV *)
CODE:
{ }

void
writeBool(SV *self, SV *value)
CODE:
{
  HV *selfh = (HV *)SvRV(self);
  
  if (unlikely(my_hv_exists(selfh, "bool_type"))) {
    // we haven't written the field header yet
    int type = SvIV(*(my_hv_fetch(selfh, "bool_type")));
    int id   = SvIV(*(my_hv_fetch(selfh, "bool_id")));
    write_field_begin_internal(self, type, id, SvTRUE(value) ? CTYPE_BOOLEAN_TRUE: CTYPE_BOOLEAN_FALSE);
    my_hv_delete(selfh, "bool_type");
    my_hv_delete(selfh, "bool_id");
  }
  else {
    // we're not part of a field, so just write the value.
    SV *trans = GET_TRANSPORT(self);
    char data[1];
    
    data[0] = SvTRUE(value) ? 1 : 0;

    WRITE(trans, data, 1);
  }
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
  char data[3];
  int varlen;
  
  uint32_t uvalue = int_to_zigzag(value);
  UINT_TO_VARINT(varlen, data, uvalue, 0);
  WRITE(trans, data, varlen);  
}

void
writeI32(SV *self, int value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[5];
  int varlen;
  
  uint32_t uvalue = int_to_zigzag(value);
  UINT_TO_VARINT(varlen, data, uvalue, 0);
  WRITE(trans, data, varlen);
}

void
writeI64(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  char data[10];
  int varlen;
  
  uint64_t uvalue = ll_to_zigzag((int64_t)SvNV(value));
  UINT_TO_VARINT(varlen, data, uvalue, 0);
  WRITE(trans, data, varlen);
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

  data[0] = u.i & 0xff;
  data[1] = (u.i >> 8) & 0xff;
  data[2] = (u.i >> 16) & 0xff;
  data[3] = (u.i >> 24) & 0xff;
  data[4] = (u.i >> 32) & 0xff;
  data[5] = (u.i >> 40) & 0xff;
  data[6] = (u.i >> 48) & 0xff;
  data[7] = (u.i >> 56) & 0xff;
  
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
  SV *data = sv_2mortal(newSV(5 + len));
  char tmp[5];
  
  int varlen;
  UINT_TO_VARINT(varlen, tmp, len, 0);
  sv_setpvn(data, tmp, varlen);
  sv_catsv(data, valuecopy);
  
  WRITE_SV(trans, data);
}

void
readMessageBegin(SV *self, SV *name, SV *type, SV *seqid)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  uint32_t tmpui;
  
  // read protocol id, version, type
  READ_SV(trans, tmp, 2);
  tmps = SvPVX(tmp);
  
  int protocol_id = tmps[0];
  if (protocol_id != PROTOCOL_ID) {
    THROW_SV("Thrift::TException", newSVpvf("Expected protocol id %d but got %d", PROTOCOL_ID, protocol_id));
  }
  
  int version_and_type = tmps[1];
  int version = version_and_type & VERSION_MASK_COMPACT;
  if (version != VERSION_N) {
    THROW_SV("Thrift::TException", newSVpvf("Expected version id %d but got %d", VERSION_N, version));
  }

  // set type
  if (SvROK(type))
    sv_setiv(SvRV(type), (version_and_type >> TYPE_SHIFT_AMOUNT) & 0x03);

  // read/set seqid
  READ_VARINT(trans, tmpui);
  if (SvROK(seqid))
    sv_setiv(SvRV(seqid), tmpui);
  
  // read/set name
  READ_VARINT(trans, tmpui);
  if (tmpui) {
    READ_SV(trans, tmp, tmpui);
    sv_utf8_decode(tmp);
    if (SvROK(name))
      sv_setsv(SvRV(name), tmp);
  }
  else {
    if (SvROK(name))
      sv_setpv(SvRV(name), "");
  }
}

void
readMessageEnd(SV *)
CODE:
{ }

void
readStructBegin(SV *self, SV *name)
CODE:
{
  // No reading here, but we push last_field_id onto the fields stack
  HV *selfh = (HV *)SvRV(self);
  
  SV *last_field_id = my_hv_delete(selfh, "last_field_id");
  AV *last_fields = (AV *)SvRV(*(my_hv_fetch(selfh, "last_fields")));
  av_push(last_fields, newSVsv(last_field_id));
  
  my_hv_store(selfh, "last_field_id", newSViv(0));
  
  if (SvROK(name))
    sv_setpv(SvRV(name), "");
}

void
readStructEnd(SV *self)
CODE:
{
  // pop last field off the stack
  HV *selfh = (HV *)SvRV(self);
  AV *last_fields = (AV *)SvRV(*(my_hv_fetch(selfh, "last_fields")));
  my_hv_store(selfh, "last_field_id", av_pop(last_fields));
}

void
readFieldBegin(SV *self, SV * /*name*/, SV *fieldtype, SV *fieldid)
CODE:
{
  HV *selfh = (HV *)SvRV(self);
  SV *trans = GET_TRANSPORT(self);
  SV *tmp;
  char *tmps;
  
  // fieldtype byte
  READ_SV(trans, tmp, 1);
  tmps = SvPVX(tmp);
  int type = tmps[0];
  
  if (SvROK(fieldtype))
    sv_setiv(SvRV(fieldtype), get_ttype(type & 0x0f));
  
  if (type == T_STOP) {
    if (SvROK(fieldid))
      sv_setiv(SvRV(fieldid), 0);
    XSRETURN_EMPTY;
  }
  
  // fieldid i16 varint
  int fid;
  
  AV *last_fields = (AV *)SvRV(*(my_hv_fetch(selfh, "last_fields")));
  
  // mask off the 4 MSB of the type header. it could contain a field id delta.
  uint8_t modifier = ((type & 0xf0) >> 4);
  if (modifier == 0) {
    // pop field    
    av_pop(last_fields);
    
    // not a delta. look ahead for the zigzag varint field id.
    READ_VARINT(trans, fid);
    fid = zigzag_to_int(fid);
  }
  else {
    // has a delta. add the delta to the last read field id.
    SV *last = av_pop(last_fields);
    fid = SvIV(last) + modifier;
  }
  
  // if this happens to be a boolean field, the value is encoded in the type
  if (is_bool_type(type)) {
    // save the boolean value in a special instance variable.
    my_hv_store((HV *)SvRV(self), "bool_value_id", newSViv((type & 0x0f) == CTYPE_BOOLEAN_TRUE ? 1 : 0));
  }
  
  // push the new field onto the field stack so we can keep the deltas going.
  av_push(last_fields, newSViv(fid));
  
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
  
  // size
  uint32_t isize;
  READ_VARINT(trans, isize);
  if (SvROK(size))
    sv_setiv(SvRV(size), isize);
  
  // key and value type
  READ_SV(trans, tmp, 1);
  tmps = SvPVX(tmp);
  
  // keytype byte
  if (SvROK(keytype))
    sv_setiv(SvRV(keytype), get_ttype((tmps[0] >> 4) & 0xf));
  
  // valtype byte
  if (SvROK(valtype))
    sv_setiv(SvRV(valtype), get_ttype(tmps[0] & 0xf));
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
  
  // size and type may be in the same byte
  READ_SV(trans, tmp, 1);
  tmps = SvPVX(tmp);
  int isize = (tmps[0] >> 4) & 0x0f;
  if (isize == 15) {
    // size is in a varint
    READ_VARINT(trans, isize);
  }
  int type = get_ttype(tmps[0] & 0x0f);

  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), type);
  
  // size
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
  
  // size and type may be in the same byte
  READ_SV(trans, tmp, 1);
  tmps = SvPVX(tmp);
  int isize = (tmps[0] >> 4) & 0x0f;
  if (isize == 15) {
    // size is in a varint
    READ_VARINT(trans, isize);
  }
  int type = get_ttype(tmps[0] & 0x0f);

  // elemtype byte
  if (SvROK(elemtype))
    sv_setiv(SvRV(elemtype), type);
  
  // size
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
  
  // Check for bool_value encoded in the fieldBegin type
  HV *selfh = (HV *)SvRV(self);
  if (my_hv_exists(selfh, "bool_value_id")) {
    SV *bool_value = *(my_hv_fetch(selfh, "bool_value_id"));
    my_hv_delete(selfh, "bool_value_id");
    if (SvROK(value))
      sv_setsv(SvRV(value), bool_value);
  }
  else {  
    READ_SV(trans, tmp, 1);
    tmps = SvPVX(tmp);
  
    if (SvROK(value))
      sv_setiv(SvRV(value), tmps[0] ? 1 : 0);
  }
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

  uint32_t varint;
  READ_VARINT(trans, varint);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), zigzag_to_int(varint));
}

void
readI32(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);

  uint32_t varint;
  READ_VARINT(trans, varint);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), zigzag_to_int(varint));
}

void
readI64(SV *self, SV *value)
CODE:
{
  SV *trans = GET_TRANSPORT(self);
  
  uint64_t varint;
  READ_VARINT(trans, varint);
  
  if (SvROK(value))
    sv_setiv(SvRV(value), zigzag_to_ll(varint));
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
  
  uint32_t lo = (uint8_t)tmps[0] |
    ((uint8_t)tmps[1] << 8) |
    ((uint8_t)tmps[2] << 16) |
    ((uint8_t)tmps[3] << 24);
  uint64_t hi = (uint8_t)tmps[4] |
    ((uint8_t)tmps[5] << 8) |
    ((uint8_t)tmps[6] << 16) |
    ((uint8_t)tmps[7] << 24);

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
  
  uint64_t len;
  READ_VARINT(trans, len);
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
