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
use POSIX qw(ceil);

use EGE::Prog;
use EGE::Random;
use EGE::Utils;

sub node_count {
    my ($self) = @_;
    my ($k, $inner) = (rnd->in_range(2, 9), rnd->in_range(50, 300));
    my ($unknown, $known) = rnd->pick_n(2,
      { name => 'внутренних ', value => $inner }, 
      { name => 'листовых ', value => 1 + ($k - 1) * $inner }, 
      { name => '', value => 1 + $k * $inner }, 
    );
    $self->{correct} = $unknown->{value};
    $self->{text} =
        'Известно, что в дереве, каждая вершина которого имеет степень исхода либо ' .
        "$k (внутренняя вершина), либо 0 (листовая вершина), имеется $known->{value} $known->{name}вершин. " .
        "Определите количество $unknown->{name}вершин в этом дереве.";
}

sub inverse_geom_sum {
    my ($x, $k) = @_;
    my ($sum, $i) = (1, 0);
    1 while ($sum += $k ** ++$i) < $x;
    $i;
}

sub height {
    my ($self) = @_;

    my $min_max = rnd->pick(qw(min max));
    my $n = rnd->pick(2..5, 10);
    my (%v, $x);
    if (rnd->coin) {
        %v = (known => 'количество вершин равно', possible => 'возможную высоту');
        $x = rnd->in_range(100, 20000);
        $self->{correct} = $min_max eq 'min' ? inverse_geom_sum($x, $n) : ceil(($x - 1) / $n);
    }
    else {
        %v = (known => 'высота равна', possible => 'возможное количество вершин');
        $x = rnd->in_range(3, 7);
        $self->{correct} = $min_max eq 'min' ? 1 + $x * $n : ($n ** ($x + 1) - 1) / ($n - 1);
    }
    my %text_min_max = (min => 'минимально', max => 'максимально');
    $self->{text} =
        'Известно, что в дереве, каждая вершина которого имеет степень исхода либо ' .
        "$n, либо 0, $v{known} $x. ".
        "Определите $text_min_max{$min_max} $v{possible} такого дерева. " .
        '(Высота дерева — максимальная длина пути от вершины дерева до его корня. ' .
        'Например, высота дерева, состоящего только из корня, равна 0.)';
}

1;
