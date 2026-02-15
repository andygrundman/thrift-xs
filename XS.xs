#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>

#include "xs_object_magic.h"
#include "common.h"
#include "buffer.c"
#include "memory_buffer.h"
#include "binary_protocol.h"

// Include the XS::Object::Magic code inline to simplify things
#include "Magic.c"

/* Detect Endianness using Perl's configuration */
#undef __LITTLE_ENDIAN
#undef __BIG_ENDIAN
#undef __BYTE_ORDER

#define __LITTLE_ENDIAN 1234
#define __BIG_ENDIAN    4321

#ifdef BYTEORDER
#  if (BYTEORDER == 0x1234 || BYTEORDER == 0x12345678)
#    define __BYTE_ORDER __LITTLE_ENDIAN
#  elif (BYTEORDER == 0x4321 || BYTEORDER == 0x87654321)
#    define __BYTE_ORDER __BIG_ENDIAN
#  endif
#endif

/* Fallback for common platforms if BYTEORDER is missing */
#ifndef __BYTE_ORDER
#  if defined(_WIN32) || defined(__i386__) || defined(__x86_64__) || defined(__alpha__)
#    define __BYTE_ORDER __LITTLE_ENDIAN
#  else
#    error "Cannot determine endianness. Please check your Perl configuration."
#  endif
#endif

/* Define a high-performance 64-bit byte swapper */
#ifndef bswap_64
#  if defined(_MSC_VER)
#    include <stdlib.h>
#    define bswap_64(n) _byteswap_uint64(n)
#  elif defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
#    define bswap_64(n) __builtin_bswap64(n)
#  else
#    define bswap_64(n) \
      ( (((n) & 0xff00000000000000ull) >> 56) \
      | (((n) & 0x00ff000000000000ull) >> 40) \
      | (((n) & 0x0000ff0000000000ull) >> 24) \
      | (((n) & 0x000000ff00000000ull) >> 8)  \
      | (((n) & 0x00000000ff000000ull) << 8)  \
      | (((n) & 0x0000000000ff0000ull) << 24) \
      | (((n) & 0x000000000000ff00ull) << 40) \
      | (((n) & 0x00000000000000ffull) << 56) )
#  endif
#endif

/* Define Host/Network macros */
#if __BYTE_ORDER == __BIG_ENDIAN
#  define ntohll(n)  (n)
#  define htonll(n)  (n)
#  define htolell(n) bswap_64(n)
#  define letohll(n) bswap_64(n)
#else
#  define ntohll(n)  bswap_64(n)
#  define htonll(n)  bswap_64(n)
#  define htolell(n) (n)
#  define letohll(n) (n)
#endif

MODULE = Thrift::XS		PACKAGE = Thrift::XS		
PROTOTYPES: ENABLE

INCLUDE: MemoryBuffer.xs
INCLUDE: BinaryProtocol.xs
INCLUDE: CompactProtocol.xs
