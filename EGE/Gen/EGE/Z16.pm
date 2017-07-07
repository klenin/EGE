# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::Z16;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Utils qw(gcd);

sub base_gcd {
    my ($self) = @_;
    my $n = rnd->in_range(3, 15);
    my $m = $n + rnd->in_range(1, 9);
    $self->{text} =
        "Запись десятичного числа в системах счисления с основаниями $n и $m " .
        'в обоих случаях имеет последней цифрой 0. ' .
        'Какое минимальное натуральное десятичное число удовлетворяет этому требованию?';
    $self->{correct} = ($n * $m) / gcd($n, $m);
    $self->accept_number;
}

1;
