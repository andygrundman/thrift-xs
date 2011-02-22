use strict;

use utf8;
use Test::More;
use Test::BinaryData;
use Thrift::XS;
use Thrift::MemoryBuffer;
use Thrift::BinaryProtocol;

plan tests => 39;

# Tests compare pure Perl output with XS output
my $xst = Thrift::XS::MemoryBuffer->new;
my $xsp = Thrift::XS::BinaryProtocol->new($xst);

my $ppt = Thrift::MemoryBuffer->new;
my $ppp = Thrift::BinaryProtocol->new($ppt);

my $test = sub {
    my $method = shift;
    $xsp->$method(@_);
    $ppp->$method(@_);
    
    # Hack to avoid wide char warnings
    if (utf8::is_utf8($_[0])) {
        utf8::encode($_[0]);
    }
    
    is_binary( $xst->read(999), $ppt->read(999), "$method ok (" . join(', ', @_) . ")" );
};

# Write tests
{
    $test->('writeMessageBegin' => 'login', TMessageType::CALL, 12345);
    my $utf8 = 'русский';
    $test->('writeMessageBegin' => $utf8, TMessageType::REPLY, 1);
    $test->('writeFieldBegin' => 'start', TType::STRING, 1);
    $test->('writeFieldStop');
    $test->('writeMapBegin' => TType::STRING, TType::LIST, 42);
    $test->('writeListBegin' => TType::STRUCT, 12345678);
    $test->('writeSetBegin' => TType::I32, 8);
    $test->('writeBool' => 1);
    $test->('writeByte' => 50);
    $test->('writeI16' => 65000);
    $test->('writeI16' => -42);
    $test->('writeI32' => 1 << 30);
    $test->('writeI32' => -60);
    $test->('writeI64' => 1 << 40);
    $test->('writeI64' => -235412341332);
    $test->('writeDouble' => 3.14159);
    $test->('writeString' => 'This is a test');
    $utf8 = 'This is a unicode test with русский';
    $test->('writeString' => $utf8);
}

# Read tests
{
    my ($name, $type, $seqid);
    $xsp->writeMessageBegin('login русский', TMessageType::CALL, 12345);
    $xsp->readMessageBegin(\$name, \$type, \$seqid);
    is($name, 'login русский', "readMessageBegin name ok");
    is($type, TMessageType::CALL, "readMessageBegin type ok");
    is($seqid, 12345, "readMessageBegin seqid ok");
}

{
    my $name;
    $xsp->writeStructBegin('foo');
    $xsp->readStructBegin(\$name);
    is($name, '', "readStructBegin name ok");
}

{
    my ($name, $type, $id);   
    $xsp->writeFieldBegin('start', TType::STRING, 2600);
    $xsp->readFieldBegin(\$name, \$type, \$id);
    # name is not returned
    is($type, TType::STRING, "readFieldBegin fieldtype ok");
    is($id, 2600, "readFieldBegin fieldid ok");
}

{
    my ($keytype, $valtype, $size);
    $xsp->writeMapBegin(TType::STRING, TType::LIST, 42);
    $xsp->readMapBegin(\$keytype, \$valtype, \$size);
    is($keytype, TType::STRING, "readMapBegin keytype ok");
    is($valtype, TType::LIST, "readMapBegin valtype ok");
    is($size, 42, "readMapBegin size ok");
}

{
    my ($elemtype, $size);
    $xsp->writeListBegin(TType::STRUCT, 12345);
    $xsp->readListBegin(\$elemtype, \$size);
    is($elemtype, TType::STRUCT, "readListBegin elemtype ok");
    is($size, 12345, "readListBegin size ok");
}

{
    my ($elemtype, $size);
    $xsp->writeSetBegin(TType::I16, 12345);
    $xsp->readSetBegin(\$elemtype, \$size);
    is($elemtype, TType::I16, "readSetBegin elemtype ok");
    is($size, 12345, "readSetBegin size ok");
}

{
    my $value;
    $xsp->writeBool('true');
    $xsp->readBool(\$value);
    is($value, 1, "readBool ok");
}

{
    my $value;
    $xsp->writeByte(100);
    $xsp->readByte(\$value);
    is($value, 100, "readByte ok");
}

{
    my $value;
    $xsp->writeI16(65534);
    $xsp->readI16(\$value);
    is($value, 65534, "readI16 ok");
}

{
    my $value;
    $xsp->writeI32(1024 * 1024);
    $xsp->readI32(\$value);
    is($value, 1024 * 1024, "readI32 ok");
}

{
    my $value;
    $xsp->writeI64((1 << 37) * -1234);
    $xsp->readI64(\$value);
    is($value, (1 << 37) * -1234, "readI64 ok");
}

{
    my $value;
    $xsp->writeDouble(-3.14159);
    $xsp->readDouble(\$value);
    is($value, -3.14159, "readDouble ok");
}

{
    my $value;
    $xsp->writeString('This is a unicode test with русский');
    $xsp->readString(\$value);
    is($value, 'This is a unicode test with русский', "readString with unicode ok");
}

{
    my $str = 'This is a unicode test with русский';
    my $value;
    $xsp->writeString($str);
    $xsp->readI32(\$value); # skip writeString len
    $xsp->readStringBody(\$value, bytes::length($str));
    is($value, $str, "readStringBody with unicode ok");
}
