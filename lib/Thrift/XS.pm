package Thrift::XS;

use strict;
use XS::Object::Magic;

use Thrift::XS::MemoryBuffer;
use Thrift::XS::BinaryProtocol;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Thrift::XS', $VERSION);

1;