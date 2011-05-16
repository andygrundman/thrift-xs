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

#ifndef htonll
// http://revoman.tistory.com/entry/Implementation-of-htonll-ntohll-uint64t-byte-ordering
uint64_t htonll(uint64_t host_longlong) {
  int x = 1;
  
  // little-endian
  if ( *(char *)&x == 1 )
    return ((((uint64_t)htonl(host_longlong)) << 32) + htonl(host_longlong >> 32));
  
  // big-endian
  else
    return host_longlong;
}
#endif

MODULE = Thrift::XS		PACKAGE = Thrift::XS		
PROTOTYPES: ENABLE

INCLUDE: MemoryBuffer.xs
INCLUDE: BinaryProtocol.xs
INCLUDE: CompactProtocol.xs
