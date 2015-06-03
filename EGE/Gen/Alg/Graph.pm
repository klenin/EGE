# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::Graph;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use List::Util qw(sum min);

sub erdos_gallai {          # критерий графичности последовательности Эрдёша — Галлаи
    my @arg = @_;
    for my $k (0 .. @_ - 2) {
        my $a = sum @_[0 .. $k];
        my $b = $k * ($k + 1) + sum map min($_, $k + 1), @_[$k + 1 .. @_ - 1];
        return 0 if $a > $b;
    }
    1;
}

sub graph_seq {
    my ($self) = @_;
    my %variants;
    my $count = 6;
    while (keys %variants < 4 || sum(values(%variants)) < 1) {
        my @seq = map rnd->in_range(1, $count - 1), 1 .. $count;
        $seq[0] == 1 ? $seq[0]++ : $seq[0]-- if sum(@seq) % 2;
        @seq = sort {$b <=> $a} @seq;
        $variants{join ',', @seq} = erdos_gallai(@seq);
    }
    my @a = (values %variants)[-4 .. -1];
    
    $self->{text} = "Графическая последовательность чисел — последовательность " .
        "целых неотрицательных чисел такая, что существует граф, последовательность " .
        "степеней вершин которого совпадает с ней. Какие из следующих " .
        "последовательностей являются графическими?";
    $self->variants((keys %variants)[-4 .. -1]);
    $self->{correct} = [ (values %variants)[-4 .. -1] ];
}

1;
