# Copyright © 2010-2012 Alexander S. Klenin
# Copyright © 2012 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::Z18;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub bitwise_conjunction {
    my ($self) = @_;
    my $p1 = rnd->in_range(1, 255);
    my $p2 = rnd->in_range_except(1, 255, $p1);
    $self->{correct} = $p1 & $p2 ^ $p1;
    $self->accept_number();
    $self->{text} = <<QUESTION
        Обозначим через m&amp;n поразрядную конъюнкцию неотрицательных целых
        чисел m и n. Так, например, 14&amp;5 = 1110<sub>2</sub>&amp;0101<sub>2</sub> = 0100<sub>2</sub> = 4.
        Для какого наименьшего неотрицательного целого числа А формула
        <p>x&amp;$p1 = 0 \/ (x&amp;$p2 = 0 → x&amp;А ≠ 0)</p>
        тождественно истинна (т.е. принимает значение 1 при любом
        неотрицательном целом значении переменной х)?
QUESTION
}

1;
