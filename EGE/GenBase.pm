# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

use strict;
use warnings;

package EGE::GenBase;

sub new {
    my ($class, %init) = @_;
    my $self = { text => undef, correct => undef };
    bless $self, $class;
    $self->init;
    $self;
}

package EGE::GenBase::SingleChoice;
use base 'EGE::GenBase';

sub init {
    $_[0]->{type} = 'sc';
    $_[0]->{correct} = 0;
}

sub variants {
    my $self = shift;
    $self->{variants} = [ @_ ];
}

package EGE::GenBase::DirectInput;
use base 'EGE::GenBase';

sub init {
    $_[0]->{type} = 'di';
}

sub accept_number {
    $_[0]->{accept} = qr/^\d+$/;
}

1;
