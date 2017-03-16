# Copyright © 2010-2017 Alexander S. Klenin
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
    my $ans = $p1 & $p2 ^ $p1;
    $self->{correct} = $ans;
    my $x = rnd->in_range(1, 255);
    die 'Z18: Wrong Genereted Answer' unless ($x & $p1) == 0 || ($x & $p2) != 0 || ($x & $ans) != 0;
    $self->accept_number();
    $self->{text} = <<QUESTION
        Обозначим через <i>m</i>&amp;<i>n</i> поразрядную конъюнкцию неотрицательных целых
        чисел <i>m</i> и <i>n</i>. Так, например, 14&amp;5 = 1110<sub>2</sub>&amp;0101<sub>2</sub> = 0100<sub>2</sub> = 4.
        Для какого наименьшего неотрицательного целого числа <i>А</i> формула
        <blockquote><i>x</i>&amp;$p1 = 0 ∨ (<i>x</i>&amp;$p2 = 0 → <i>x</i>&amp;<i>А</i> ≠ 0)</blockquote>
        тождественно истинна (т.е. принимает значение 1 при любом
        неотрицательном целом значении переменной <i>х</i>)?
QUESTION
}

1;
