# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B03;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NotationBase;

sub q1234 {
    my ($self) = @_;
    my $base = rnd->pick(5, 6, 7, 9, 11);
    $self->{text} =
        "Какое десятичное число в системе счиаления по основанию $base " .
        "записываетяс как 1234<sub>$base</sub>?";
    $self->{correct} = EGE::NotationBase::base_to_dec($base, 1234);
    $self->accept_number;
}

1;
