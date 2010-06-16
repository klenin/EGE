# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B04;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use List::Util qw(sum first);

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;

sub make_xx {[
    '*', map rnd->pick('X', [ '+', 'X', 1 ], [ '-', 'X', 1 ]), 1 .. 2
]}

sub make_side {
    [ rnd->pick(qw(> < >= <=)), make_xx(), rnd->in_range(30, 99) ]
}

sub find_first {
    my ($v, $q) = @_;
    $q->[$_] == $v and return $_ for 0 .. $#$q;
    -1;
}

sub find_last {
    my ($v, $q) = @_;
    $q->[-$_] == $v and return @$q - $_ for 1 .. @$q;
    -1;
}

sub between { $_[1] <= $_[0] && $_[0] <= $_[2] }

sub impl_border {
    my ($self) = @_;
    my $n = 15;

    my ($e, @values);
    do {
        $e = EGE::Prog::make_expr([ '=>', make_side, make_side ]);
        @values = map $e->run({ X => $_ }), 0 .. $n;
    } until between sum(@values), 1, $n;

    my $et = html->cdata($e->to_lang_named('Logic'));

    my $facet = first { between $_->{v}, 1, $n - 1 } rnd->shuffle(map {
        t1 => [ qw(наименьшее наибольшее) ]->[$_ / 2],
        t2 => [ qw(ложно истинно) ]->[$_ % 2],
        v => ($_ < 2 ? \&find_first : \&find_last)->($_ % 2, \@values),
    }, 0 .. 3);
    $self->{text} =
        "Каково $facet->{t1} целое число X, " .
        "при котором $facet->{t2} высказывание $et?";
    $self->{correct} = $facet->{v};
    $self->accept_number;
}

1;
