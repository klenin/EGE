# Copyright © 2014 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Utils;


use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(transpose last_key aggregate_function tail product gcd);

sub aggregate_function {
    my ($name) = @_;
    my %aggr = %EGE::SQL::Table::Aggregate::;
    return defined $aggr{ $name . '::' } if defined $name;
    map substr ($_, -length($_), -2), keys %aggr;
}

sub transpose {
    @_ or die;
    [ map { my $i = $_; [ map $_->[$i], @_ ]; } 0 .. $#{$_[0]} ];
}

sub last_key {
    my ($hash_ref, $key) = @_;
    defined $hash_ref->{$key} or die "There is not such key: '$key' in hash";
    $key = $hash_ref->{$key} while defined $hash_ref->{$hash_ref->{$key}};
    $key;
}

sub tail { @_[1..$#_] }

sub product {
    my $r = 1;
    $r *= $_ for @_;
    $r;
}

sub gcd {
    my ($n, $m) = @_;
    ($n, $m) = ($m, $n % $m) while $m;
    $n;
}

sub median {
    @_ or die 'empty';
    my $sorted = [ sort @_ ];
    @_ % 2 ? $sorted->[@_ / 2] : ($sorted->[@_ / 2] + $sorted->[@_ / 2 + 1]) / 2;
}

sub distinct_letters_count {
    my %h;
    @h{split '', $_[0]} = undef;
    scalar keys %h;
}

1;
