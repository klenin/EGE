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

sub in_range_except {
    my ($self, $lo, $hi, $except) = @_;
    my @ex = ref $except ? sort { $a <=> $b } @$except : ($except);
    my $r = $self->in_range($lo, $hi - @ex);
    for (@ex) {
        last if $_ > $r;
        $r++;
    }
    $r;
}

sub pick {
    my ($self, @array) = @_;
    @array or die 'pick from empty array';
    @array[rand @array];
}

sub pick_n {
    my ($self, $n, @array) = @_;
    die "pick_n: $n of " . scalar @array if $n > @array;
    --$n;
    for (0 .. $n) {
        my $pos = $self->in_range($_, $#array);
        @array[$_, $pos] = @array[$pos, $_];
    }
    @array[0 .. $n];
}

# Выражение вида sort rnd->pick_n вызывает синтаксическую ошибку,
# поэтому заводим специальную функцию.
sub pick_n_sorted {
    my $self = shift;
    sort $self->pick_n(@_);
}

sub coin { rand(2) > 1 ? 1 : 0 }

sub shuffle {
    my $self = shift;
    $self->pick_n(scalar @_, @_);
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

sub split_number {
    my ($self, $number, $parts) = @_;
    die if $parts > $number;
    my @p = sort { $a <=> $b } $self->pick_n($parts - 1, 1 .. $number - 1);
    $p[0], map($p[$_] - $p[$_ - 1], 1 .. $#p), $number - $p[-1];
}

1;
