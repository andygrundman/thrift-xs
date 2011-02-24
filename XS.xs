#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "xs_object_magic.h"
#include "common.h"
#include "binary_protocol.h"
#include "buffer.c"
#include "memory_buffer.h"

MODULE = Thrift::XS		PACKAGE = Thrift::XS		
PROTOTYPES: ENABLE

INCLUDE: MemoryBuffer.xs
INCLUDE: BinaryProtocol.xs
INCLUDE: CompactProtocol.xs
