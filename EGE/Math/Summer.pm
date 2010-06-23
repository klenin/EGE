# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Math::Summer;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use Encode;

use EGE::Random;

sub g {
    my ($method) = @_;
    my $g = EGE::Math::Summer->new;
    $g->$method;
    $g->post_process;
    $g;
}

sub gcd {
    my ($x, $y) = @_;
    ($x, $y) = ($y, $x % $y) while $y > 0;
    $x;
}

sub lcm {
    my ($x, $y) = @_;
    $x * $y / gcd($x, $y);
}

sub fact {
    my ($n) = @_;
    my $f = 1;
    $f *= $_ for 2 .. $n;
    $f;
}

sub C {
    my ($n, $m) = @_;
    fact($m) / fact($n) / fact($m - $n);
}

sub p1 {
    my ($self) = @_;
    my @pr = rnd->pick_n(2, 3, 5, 7);
    my @pw = map rnd->in_range(5, 6), @pr;
    my $L = 1;
    $L *= $pr[$_] ** $pw[$_] for 0 .. $#pr;
    $self->{text} =
        'Каково количество различных пар натуральных чисел (a, b) таких, ' .
        "что наименьшее общее кратное a и b равно $L?";
    $self->{correct} = ($pw[0] + 1) * ($pw[1] + 1) + $pw[0] * $pw[1];
}

sub p2 {
    my ($self) = @_;
    my $n = rnd->in_range(20, 25) * 10;
    my $d = rnd->pick(3, 5);
    my $c = 0;
    my @cm = map [ 1, (0) x $n ], 1 .. 2;
    for my $i (1 .. $n + 1) {
        $cm[1]->[$i] = 1;
        $cm[1]->[$_] = ($cm[0]->[$_ - 1] + $cm[0]->[$_]) % $d
            for 1 .. $n - 1;
        @cm[0, 1] = @cm[1, 0];
    }
    $self->{text} =
        "Сколько чисел вида <i><b>C<sub>$n</sub><sup>i</sup></b></i> делятся на $d?";
    $self->{correct} = grep !$_, @{$cm[1]};
}

sub p3 {
    my ($self) = @_;
    my $g = rnd->in_range(10, 20);
    my $t = rnd->in_range(10, 20);
    my $n = $g + $t;
    my $facet = rnd->pick(
        { n => 'лучей', d => 1 },
        { n => 'прямых', d => 2 },
    );
    $self->{text} =
        "Дано $n точек на плоскости, из которых $t лежат на одной прямой, " .
        'а из остальных точек никакие три не лежат на одной прямой. ' .
        "Сколько различных $facet->{n} можно провести через эти точки?";
    $self->{correct} = ($g * ($g - 1) + $g * $t * 2 + 2) / $facet->{d};
}

sub p4 {
    my ($self) = @_;
    my $xc = rnd->in_range(400, 500) * 10;
    my $yc = rnd->in_range(400, 500) * 10;
    my $r = rnd->in_range(10, 20) * 10;
    my $q = 1;
    for (; $q < 20000; ++$q) {
        my $k = 10000 / $q;
        # (x - xc)^2 + (y - yc)^2 = r^2
        # y = k * x
        # x^2 - 2*x*xc + xc^2 + k^2 * x^2 - 2 * k * x * yc + yc^2 = r^2
        # (k + 1) * x^2 - (2 * xc + 2 * k * yc) * x + xc^2 + yc^2 - r^2 = 0
        my $d =
            (2 * $xc + 2 * $k * $yc) ** 2 -
            4 * ($k ** 2 + 1) * ($xc ** 2 + $yc ** 2 - $r ** 2);
        last if $d >= 0;
    }
    $self->{text} =
        "При каком наименьшем целом <i>q</i> прямая, проходящая через начало " .
        "координат и точку (10000, <i>q</i>), пересекает окружность " .
        "с центром в точке ($xc, $yc) и радиусом $r?";
    $self->{correct} = $q;
}

1;
