#ifndef _BINARY_PROTOCOL_H
#define _BINARY_PROTOCOL_H

#include <stdint.h>

#include "common.h"

// normal types
enum TType {
  T_STOP       = 0,
  T_VOID       = 1,
  T_BOOL       = 2,
  T_BYTE       = 3,
  T_I08        = 3,
  T_I16        = 6,
  T_I32        = 8,
  T_U64        = 9,
  T_I64        = 10,
  T_DOUBLE     = 4,
  T_STRING     = 11,
  T_UTF7       = 11,
  T_STRUCT     = 12,
  T_MAP        = 13,
  T_SET        = 14,
  T_LIST       = 15,
  T_UTF8       = 16,
  T_UTF16      = 17
};

const int32_t VERSION_MASK = 0xffff0000;
const int32_t VERSION_1 = 0x80010000;
const int8_t T_CALL = 1;
const int8_t T_REPLY = 2;
const int8_t T_EXCEPTION = 3;
// tprotocolexception
const int INVALID_DATA = 1;
const int BAD_VERSION = 4;

// compact types
enum CType {
  CTYPE_BOOLEAN_TRUE  = 0x01,
  CTYPE_BOOLEAN_FALSE = 0x02,
  CTYPE_BYTE          = 0x03,
  CTYPE_I16           = 0x04,
  CTYPE_I32           = 0x05,
  CTYPE_I64           = 0x06,
  CTYPE_DOUBLE        = 0x07,
  CTYPE_BINARY        = 0x08,
  CTYPE_LIST          = 0x09,
  CTYPE_SET           = 0x0A,
  CTYPE_MAP           = 0x0B,
  CTYPE_STRUCT        = 0x0C
};

static const int8_t  PROTOCOL_ID = (int8_t)0x82;
static const int8_t  VERSION_N = 1;
static const int8_t  VERSION_MASK_COMPACT = 0x1f; // 0001 1111
static const int8_t  TYPE_MASK = (int8_t)0xE0; // 1110 0000
static const int32_t TYPE_SHIFT_AMOUNT = 5;

#define is_bool_type(ctype) (((ctype) & 0x0F) == CTYPE_BOOLEAN_TRUE || ((ctype) & 0x0F) == CTYPE_BOOLEAN_FALSE)

#define INT_TO_I32(dst, src, off)   \
  dst[3+off] = src & 0xff;          \
  dst[2+off] = (src >> 8) & 0xff;   \
  dst[1+off] = (src >> 16) & 0xff;  \
  dst[0+off] = (src >> 24) & 0xff

#define INT_TO_I16(dst, src, off)   \
  dst[1+off] = src & 0xff;          \
  dst[0+off] = (src >> 8) & 0xff

#define I32_TO_INT(dst, src, off)   \
  dst = ((uint8_t)src[3+off] |      \
  (((uint8_t)src[2+off]) << 8) |    \
  (((uint8_t)src[1+off]) << 16) |   \
  (((uint8_t)src[0+off]) << 24))

#define I16_TO_INT(dst, src, off)   \
  dst = ((uint8_t)src[1+off] |      \
  (((uint8_t)src[0+off]) << 8))

#define GET_TRANSPORT(self) *(my_hv_fetch((HV *)SvRV(self), "trans"))

#define WRITE(trans, str, len)             \
  dSP; ENTER; SAVETMPS;                    \
  PUSHMARK(SP);                            \
  XPUSHs(trans);                           \
  XPUSHs(sv_2mortal(newSVpvn(str, len)));  \
  PUTBACK;                                 \
  call_method("write", G_DISCARD);         \
  FREETMPS; LEAVE

#define WRITE_SV(trans, sv)                \
  dSP; ENTER; SAVETMPS;                    \
  PUSHMARK(SP);                            \
  XPUSHs(trans);                           \
  XPUSHs(sv);                              \
  PUTBACK;                                 \
  call_method("write", G_DISCARD);         \
  FREETMPS; LEAVE

#define READ_SV(trans, dst, len)           \
  dSP; ENTER; SAVETMPS;                    \
  PUSHMARK(SP);                            \
  XPUSHs(trans);                           \
  XPUSHs(sv_2mortal(newSViv(len)));        \
  PUTBACK;                                 \
  call_method("readAll", G_SCALAR);        \
  SPAGAIN;                                 \
  dst = newSVsv(POPs);                     \
  PUTBACK;                                 \
  FREETMPS; LEAVE;                         \
  sv_2mortal(dst)

// These work for both 32-bit and 64-bit
#define UINT_TO_VARINT(len, dst, src, off)   \
  {                                            \
    len = 0;                                   \
    while (src > 0x7f) {                       \
      dst[off + len++] = (src & 0x7f) | 0x80;  \
      src >>= 7;                               \
    }                                          \
    dst[off + len++] = src & 0x7f;             \
  }

// dst can be a uint32_t or uint64_t
#define READ_VARINT(trans, dst)                           \
  {                                                       \
    dst = 0;                                              \
    int count = 0;                                        \
    SV *b;                                                \
    char *bs;                                             \
    do {                                                  \
      if (count == 10) {                                  \
        dst = 0;                                          \
        break;                                            \
      }                                                   \
      READ_SV(trans, b, 1);                               \
      bs = SvPVX(b);                                      \
      dst |= (uint64_t)(bs[0] & 0x7f) << (7 * count);     \
      ++count;                                            \
    } while (bs[0] & 0x80);                               \
  }    

static int get_compact_type(int type) {
  switch (type) {
    case T_BOOL:   return CTYPE_BOOLEAN_TRUE;
    case T_BYTE:   return CTYPE_BYTE;
    case T_I16:    return CTYPE_I16;
    case T_I32:    return CTYPE_I32;
    case T_I64:    return CTYPE_I64;
    case T_DOUBLE: return CTYPE_DOUBLE;
    case T_STRING: return CTYPE_BINARY;
    case T_LIST:   return CTYPE_LIST;
    case T_SET:    return CTYPE_SET;
    case T_MAP:    return CTYPE_MAP;
    case T_STRUCT: return CTYPE_STRUCT;
    default:
    {
      THROW_SV("Thrift::TException", newSVpvf("Cannot convert type %d to compact protocol", type));
    }
  }
}

static int get_ttype(int ctype) {
  switch (ctype) {
    case T_STOP:                  return T_STOP;
    case CTYPE_BOOLEAN_TRUE:
    case CTYPE_BOOLEAN_FALSE:     return T_BOOL;
    case CTYPE_BYTE:              return T_BYTE;
    case CTYPE_I16:               return T_I16;
    case CTYPE_I32:               return T_I32;
    case CTYPE_I64:               return T_I64;
    case CTYPE_DOUBLE:            return T_DOUBLE;
    case CTYPE_BINARY:            return T_STRING;
    case CTYPE_LIST:              return T_LIST;
    case CTYPE_SET:               return T_SET;
    case CTYPE_MAP:               return T_MAP;
    case CTYPE_STRUCT:            return T_STRUCT;
    default:
    {
      THROW_SV("Thrift::TException", newSVpvf("Cannot convert type %d from compact protocol", ctype));
    }
  }
}

static inline uint32_t
int_to_zigzag(int n)
{
  return (uint32_t)((n << 1) ^ (n >> 31));
}

static inline int32_t
zigzag_to_int(uint32_t n) {
  return (n >> 1) ^ -(n & 1);
}

static inline uint64_t
ll_to_zigzag(int64_t n)
{
  return (uint64_t)((n << 1) ^ (n >> 63));
}

static inline int64_t
zigzag_to_ll(uint64_t n)
{
  return (n >> 1) ^ -(n & 1);
}

static void
write_field_begin_internal(SV *self, int type, int id, int type_override)
{
  SV *trans = GET_TRANSPORT(self);
  HV *selfh = (HV *)SvRV(self);
  char data[4];
  
  // Get last ID
  int last_field_id = SvIV(*(my_hv_fetch(selfh, "last_field_id")));
  
  int type_to_write = type_override == -1 ? get_compact_type(type) : type_override;
  
  DEBUG_TRACE("id %d, last_field_id %d, type_to_write %d\n", id, last_field_id, type_to_write);
  
  // check if we can use delta encoding for the field id
  if (id > last_field_id && id - last_field_id <= 15) {
    // write them together
    data[0] = ((id - last_field_id) << 4) | type_to_write;
    WRITE(trans, data, 1);
  }
  else {
    // write them separate
    int varlen;
    data[0] = type_to_write;
    uint32_t uid = int_to_zigzag(id);

    UINT_TO_VARINT(varlen, data, uid, 1);
    WRITE(trans, data, varlen + 1);
  }
  
  my_hv_store(selfh, "last_field_id", newSViv(id));
}

static void
write_collection_begin_internal(SV *self, int elemtype, uint32_t size)
{
  SV *trans = GET_TRANSPORT(self);
  char data[6];
  
  if (size <= 14) {
    data[0] = (size << 4) | get_compact_type(elemtype);
    WRITE(trans, data, 1);
  }
  else {
    int varlen;
    data[0] = 0xf0 | get_compact_type(elemtype);
    UINT_TO_VARINT(varlen, data, size, 1);
    WRITE(trans, data, varlen + 1);
  }
}

#endif
