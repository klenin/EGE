# Copyright © 2015 Alexander S. Klenin
# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::Tree;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use List::Util;

use EGE::Prog;
use EGE::Random;
use EGE::Utils;

sub node_count {
    my ($self) = @_;
    my ($k, $inner) = (rnd->in_range(2, 9), rnd->in_range(50, 300));
    my %data = ( внутренних => $inner, листовых => 1 + ($k - 1) * $inner, '' => 1 + $k * $inner );
    my ($unknown, $know) = (rnd->shuffle(keys %data))[0 .. 1];
    $self->{correct} = $data{$unknown};
    $self->{text} = "Известно, что в дереве, каждый узел которого имеет степень либо " .
    "$k(внутренний узел), либо 0(листовой узел), имеется $data{$know} $know узлов." .
    " Определеите количество $unknown узлов в этом дереве";
}

sub inverse_geom_sum {
    my ($x, $k) = @_;
    my ($sum, $i) = (1, 0);
    while (($sum += $k ** ++$i) < $x) {}
    $i;
}

use POSIX qw/ceil/;

sub height {
    my ($self) = @_;
    my $k = rnd->in_range(2, 9);
    my ($height_count, $max_min) = (map rnd->coin, 1 .. 2);
    my @text_max_min = qw(Макс. Мин.);
    my @text_height_count = ('высота', 'количество узлов');
    my @text_eq = qw(равна равно);

    my $know =  $height_count ? rnd->in_range(3, 7) : rnd->in_range(100, 20000);
    my $num = 1 * $height_count + 2 * $max_min;
    my $sol = $num == 0 ? ceil(($know - 1) / $k):
        $num == 1 ? (1 - $k ** ($know + 1)) / (1 - $k):
        $num == 2 ? inverse_geom_sum($know, $k):
        1 + $know * $k;
    $self->{correct} = $sol;
    $self->{text} = "Известно, что в дереве, каждый узел которого имеет степень либо " .
    "$k, либо 0, $text_height_count[!$height_count] $text_eq[!$height_count] $know." .
    "$text_max_min[$max_min] $text_height_count[$height_count] такого дерева $text_eq[$height_count]?" .
    "(Высота дерева - максимальная длина пути от узла дерева до его корня, " .
    "напр. высота дерева состоящего только из корня равна 0)";
}
1;
