#include <stdint.h>

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

#define INT_TO_I32(dst, src, off)   \
  dst[3+off] = src & 0xff;          \
  dst[2+off] = (src >> 8) & 0xff;   \
  dst[1+off] = (src >> 16) & 0xff;  \
  dst[0+off] = (src >> 24) & 0xff

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
