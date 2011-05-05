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

MODULE = Thrift::XS		PACKAGE = Thrift::XS		
PROTOTYPES: ENABLE

INCLUDE: MemoryBuffer.xs
INCLUDE: BinaryProtocol.xs
INCLUDE: CompactProtocol.xs
