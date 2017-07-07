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
    my $x = rnd->in_range(1, 255);
    ($x & $p1) == 0 || ($x & $p2) != 0 || ($x & $ans) != 0 or die;
    my $and = '&nbsp;&amp;&nbsp;';
    $self->{text} = <<QUESTION
        Обозначим через <i>m</i>$and<i>n</i> поразрядную конъюнкцию неотрицательных целых чисел <i>m</i> и <i>n</i>.
        Так, например, 14${and}5 = 1110<sub>2</sub>${and}0101<sub>2</sub> = 0100<sub>2</sub> = 4.
        Для какого наименьшего неотрицательного целого числа <i>А</i> формула
        <blockquote><i>x</i>$and$p1 = 0 ∨ (<i>x</i>$and$p2 = 0 → <i>x</i>$and<i>А</i> ≠ 0)</blockquote>
        тождественно истинна (т.е. принимает значение 1 при любом
        неотрицательном целом значении переменной <i>х</i>)?
QUESTION
;
    $self->{correct} = $ans;
    $self->accept_number;
}

1;
