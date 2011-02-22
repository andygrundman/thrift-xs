#!/usr/bin/perl

use strict;

use Benchmark qw(cmpthese);
use Thrift::XS;
use Thrift::MemoryBuffer;
use Thrift::BinaryProtocol;

my $xst = Thrift::XS::MemoryBuffer->new;
my $xsp = Thrift::XS::BinaryProtocol->new($xst);

my $ppt = Thrift::MemoryBuffer->new;
my $ppp = Thrift::BinaryProtocol->new($ppt);

#                     Rate MemoryBuffer_pp MemoryBuffer_xs
# MemoryBuffer_pp 120993/s              --            -84%
# MemoryBuffer_xs 778645/s            544%              --
#
cmpthese( -5, {
    MemoryBuffer_xs => sub {
        $xst->write( "a" x 256 );
        $xst->readAll(256);
    },
    MemoryBuffer_pp => sub {
        $ppt->write( "a" x 256 );
        $ppt->readAll(256);
        $ppt->resetBuffer(); # Perl version never compacts the buffer without this
    },
} );

#                                   Rate BinaryProtocol_MessageBegin_pp BinaryProtocol_MessageBegin_xs
# BinaryProtocol_MessageBegin_pp 21353/s                             --                           -78%
# BinaryProtocol_MessageBegin_xs 98833/s                           363%                             --
#
cmpthese( -5, {
    BinaryProtocol_MessageBegin_xs => sub {
        my ($name, $type, $seqid);
        $xsp->writeMessageBegin('login русский', TMessageType::CALL, 12345);
        $xsp->readMessageBegin(\$name, \$type, \$seqid);
    },
    BinaryProtocol_MessageBegin_pp => sub {
        my ($name, $type, $seqid);
        $ppp->writeMessageBegin('login русский', TMessageType::CALL, 12345);
        $ppp->readMessageBegin(\$name, \$type, \$seqid);
        $ppt->resetBuffer();
    },
} );

#                                    Rate BinaryProtocol_StructBegin_pp BinaryProtocol_StructBegin_xs
# BinaryProtocol_StructBegin_pp  332809/s                            --                          -77%
# BinaryProtocol_StructBegin_xs 1429163/s                          329%                            --
#
cmpthese( -5, {
    BinaryProtocol_StructBegin_xs => sub {
        my $name;
        $xsp->writeStructBegin('foo');
        $xsp->readStructBegin(\$name);
    },
    BinaryProtocol_StructBegin_pp => sub {
        my $name;
        $ppp->writeStructBegin('foo');
        $ppp->readStructBegin(\$name);
        $ppt->resetBuffer();
    },
} );

#                                  Rate BinaryProtocol_FieldBegin_pp BinaryProtocol_FieldBegin_xs
# BinaryProtocol_FieldBegin_pp  38252/s                           --                         -84%
# BinaryProtocol_FieldBegin_xs 245291/s                         541%                           --
#
cmpthese( -5, {
    BinaryProtocol_FieldBegin_xs => sub {
        my ($name, $type, $id);   
        $xsp->writeFieldBegin('start', TType::STRING, 2600);
        $xsp->readFieldBegin(\$name, \$type, \$id);
    },
    BinaryProtocol_FieldBegin_pp => sub {
        my ($name, $type, $id);   
        $ppp->writeFieldBegin('start', TType::STRING, 2600);
        $ppp->readFieldBegin(\$name, \$type, \$id);
        $ppt->resetBuffer();
    },
} );

#                                Rate BinaryProtocol_MapBegin_pp BinaryProtocol_MapBegin_xs
# BinaryProtocol_MapBegin_pp  28869/s                         --                       -88%
# BinaryProtocol_MapBegin_xs 237734/s                       723%                         --
#
cmpthese( -5, {
    BinaryProtocol_MapBegin_xs => sub {
        my ($keytype, $valtype, $size);
        $xsp->writeMapBegin(TType::STRING, TType::LIST, 42);
        $xsp->readMapBegin(\$keytype, \$valtype, \$size);
    },
    BinaryProtocol_MapBegin_pp => sub {
        my ($keytype, $valtype, $size);
        $ppp->writeMapBegin(TType::STRING, TType::LIST, 42);
        $ppp->readMapBegin(\$keytype, \$valtype, \$size);
        $ppt->resetBuffer();
    },
} );

#                                 Rate BinaryProtocol_ListBegin_pp BinaryProtocol_ListBegin_xs
# BinaryProtocol_ListBegin_pp  39519/s                          --                        -85%
# BinaryProtocol_ListBegin_xs 258000/s                        553%                          --
#
cmpthese( -5, {
    BinaryProtocol_ListBegin_xs => sub {
        my ($elemtype, $size);
        $xsp->writeListBegin(TType::STRUCT, 12345);
        $xsp->readListBegin(\$elemtype, \$size);
    },
    BinaryProtocol_ListBegin_pp => sub {
        my ($elemtype, $size);
        $ppp->writeListBegin(TType::STRUCT, 12345);
        $ppp->readListBegin(\$elemtype, \$size);
        $ppt->resetBuffer();
    },
} );

#                                Rate BinaryProtocol_SetBegin_pp BinaryProtocol_SetBegin_xs
# BinaryProtocol_SetBegin_pp  39898/s                         --                       -84%
# BinaryProtocol_SetBegin_xs 257027/s                       544%                         --
#
cmpthese( -5, {
    BinaryProtocol_SetBegin_xs => sub {
        my ($elemtype, $size);
        $xsp->writeSetBegin(TType::I16, 12345);
        $xsp->readSetBegin(\$elemtype, \$size);
    },
    BinaryProtocol_SetBegin_pp => sub {
        my ($elemtype, $size);
        $ppp->writeSetBegin(TType::I16, 12345);
        $ppp->readSetBegin(\$elemtype, \$size);
        $ppt->resetBuffer();
    },
} );

#                            Rate BinaryProtocol_Bool_pp BinaryProtocol_Bool_xs
# BinaryProtocol_Bool_pp  82548/s                     --                   -71%
# BinaryProtocol_Bool_xs 281096/s                   241%                     --
#
cmpthese( -5, {
    BinaryProtocol_Bool_xs => sub {
        my $value;
        $xsp->writeBool('true');
        $xsp->readBool(\$value);
    },
    BinaryProtocol_Bool_pp => sub {
        my $value;
        $ppp->writeBool('true');
        $ppp->readBool(\$value);
        $ppt->resetBuffer();
    },
} );

#                            Rate BinaryProtocol_Byte_pp BinaryProtocol_Byte_xs
# BinaryProtocol_Byte_pp  83359/s                     --                   -70%
# BinaryProtocol_Byte_xs 281590/s                   238%                     --
#
cmpthese( -5, {
    BinaryProtocol_Byte_xs => sub {
        my $value;
        $xsp->writeByte(100);
        $xsp->readByte(\$value);
    },
    BinaryProtocol_Byte_pp => sub {
        my $value;
        $ppp->writeByte(100);
        $ppp->readByte(\$value);
        $ppt->resetBuffer();
    },
} );

#                           Rate BinaryProtocol_I16_pp BinaryProtocol_I16_xs
# BinaryProtocol_I16_pp  77024/s                    --                  -72%
# BinaryProtocol_I16_xs 278971/s                  262%                    --
#
cmpthese( -5, {
    BinaryProtocol_I16_xs => sub {
        my $value;
        $xsp->writeI16(65534);
        $xsp->readI16(\$value);
    },
    BinaryProtocol_I16_pp => sub {
        my $value;
        $ppp->writeI16(65534);
        $ppp->readI16(\$value);
        $ppt->resetBuffer();
    },
} );

#                           Rate BinaryProtocol_I32_pp BinaryProtocol_I32_xs
# BinaryProtocol_I32_pp  81771/s                    --                  -71%
# BinaryProtocol_I32_xs 277920/s                  240%                    --
#
cmpthese( -5, {
    BinaryProtocol_I32_xs => sub {
        my $value;
        $xsp->writeI32(1024 * 1024);
        $xsp->readI32(\$value);
    },
    BinaryProtocol_I32_pp => sub {
        my $value;
        $ppp->writeI32(1024 * 1024);
        $ppp->readI32(\$value);
        $ppt->resetBuffer();
    },
} );

#                           Rate BinaryProtocol_I64_pp BinaryProtocol_I64_xs
# BinaryProtocol_I64_pp  37941/s                    --                  -86%
# BinaryProtocol_I64_xs 274644/s                  624%                    --
#
cmpthese( -5, {
    BinaryProtocol_I64_xs => sub {
        my $value;
        $xsp->writeI64((1 << 37) * -1234);
        $xsp->readI64(\$value);
    },
    BinaryProtocol_I64_pp => sub {
        my $value;
        $ppp->writeI64((1 << 37) * -1234);
        $ppp->readI64(\$value);
        $ppt->resetBuffer();
    },
} );

#                              Rate BinaryProtocol_Double_pp BinaryProtocol_Double_xs
# BinaryProtocol_Double_pp  81147/s                       --                     -70%
# BinaryProtocol_Double_xs 270489/s                     233%                       --
#
cmpthese( -5, {
    BinaryProtocol_Double_xs => sub {
        my $value;
        $xsp->writeDouble(-3.14159);
        $xsp->readDouble(\$value);
    },
    BinaryProtocol_Double_pp => sub {
        my $value;
        $ppp->writeDouble(-3.14159);
        $ppp->readDouble(\$value);
        $ppt->resetBuffer();
    },
} );

#                              Rate BinaryProtocol_String_pp BinaryProtocol_String_xs
# BinaryProtocol_String_pp  44995/s                       --                     -69%
# BinaryProtocol_String_xs 145598/s                     224%                       --
#
cmpthese( -5, {
    BinaryProtocol_String_xs => sub {
        my $value;
        $xsp->writeString('This is a unicode test with русский');
        $xsp->readString(\$value);
    },
    BinaryProtocol_String_pp => sub {
        my $value;
        $ppp->writeString('This is a unicode test with русский');
        $ppp->readString(\$value);
        $ppt->resetBuffer();
    },
} );
