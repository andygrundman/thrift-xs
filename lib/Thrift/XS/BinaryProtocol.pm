package Thrift::XS::BinaryProtocol;

use strict;
use base('Thrift::Protocol');

# Most implementation is in XS.xs

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    return bless $self, $class;
}

1;
