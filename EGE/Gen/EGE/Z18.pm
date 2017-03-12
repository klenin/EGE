# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::Z18;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NotationBase qw(dec_to_base);

sub notation {
    my ($self) = @_;
    
    my $dec_num = rnd->in_range(12, 150);
    my $base = rnd->in_range(3, 9);
    my $ans = dec_to_base($base, $dec_num);
    $self->{text} =
        "В системе счисления с некоторым основанием десятичное число $dec_num записывается в виде $ans. Укажите это основание.";
    $self->{correct} = $base;
    $self->accept_number;
}

1;
