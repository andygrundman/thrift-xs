#!/usr/bin/perl

use Config;

if ( $Config{myarchname} =~ /i386/ ) {
    my $arch;
    
    # Match arch options with the running perl
    if ( my @archs = $Config{ccflags} =~ /-arch ([^ ]+)/g ) {
        $arch = join( '', map { "-arch $_ " } @archs );
        if ( -e 'MANIFEST.SKIP' ) {
            # XXX for development, use only one arch to speed up compiles
            $arch = '-arch x86_64 ';
        }
    }

    print "Adding $arch\n" if $arch;

    my $ccflags   = $Config{ccflags};
    my $ldflags   = $Config{ldflags};
    my $lddlflags = $Config{lddlflags};
    
    # Remove extra -arch flags from these
    $ccflags  =~ s/-arch\s+\w+//g;
    $ldflags  =~ s/-arch\s+\w+//g;
    $lddlflags =~ s/-arch\s+\w+//g;
    
    $self->{CCFLAGS} = "$arch -I/usr/include $ccflags";
    $self->{LDFLAGS} = "$arch -L/usr/lib $ldflags";
    $self->{LDDLFLAGS} = "$arch -L/usr/lib $lddlflags";
}
