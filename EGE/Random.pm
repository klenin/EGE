# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Random;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(rnd);

use List::Util;

my $rnd;

sub rnd {
    $rnd ||= EGE::Random->new;
}

sub new {
    my $self = {};
    bless $self, shift;
    $self;
}

sub in_range {
    my ($self, $lo, $hi) = @_;
    int rand($hi - $lo + 1) + $lo;
}

sub pick {
    my ($self, @array) = @_;
    @array[rand @array];
}

sub pick_n {
    my ($self, $n, @array) = @_;
    @array = List::Util::shuffle @array;
    @array[0 .. $n - 1];
}

# Выражение вида sort rnd->pick_n вызывает синтаксическую ошибку,
# поэтому заводим специальную функцию.
sub pick_n_sorted {
    my $self = shift;
    sort $self->pick_n(@_);
}

sub coin { rand(2) > 1 }

sub shuffle {
    shift;
    List::Util::shuffle(@_);
}

sub index_var {
    my ($self, $n) = @_;
    $self->pick_n($n || 1, 'i', 'j', 'k', 'm', 'n')
}

sub english_letter { $_[0]->pick('a' .. 'z') }

sub russian_letter {
    my ($self) = @_;
    chr([ord('а') .. ord('я')]->[rnd->in_range(0, 31)]);
}

sub pretty_russian_letter {
    my ($self) = @_;
    my $pretty = 'абвгдежзиклмнопрстуфхэя';
    substr($pretty, rnd->in_range(0, length($pretty) - 1), 1);
}

1;
