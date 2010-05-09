package EGE::Generate;

use strict;
use warnings;
use utf8;

use EGE::Random;

use EGE::Gen::A01;
use EGE::Gen::A02;
use EGE::Gen::A03;
use EGE::Gen::A04;
use EGE::Gen::A05;
use EGE::Gen::A06;
use EGE::Gen::A07;
use EGE::Gen::A08;
use EGE::Gen::A09;
use EGE::Gen::A10;

sub one {
    no strict 'refs';
    "EGE::Gen::$_[0]::$_[1]"->();
}

sub g {
    my $unit = shift;
    my ($p, $n) = ($unit =~ /^(\w)(\d+)$/);
    my $q = one sprintf('%s%02d', $p, $n), rnd->pick(@_);
    $q->{question} = "<h3>$unit</h3>\n$q->{question}";
    $q;
}

sub gg {
    my $unit = shift;
    map g($unit, $_), @_;
}

sub all {[
    g('A1', qw(recode simple)),
    g('A2', qw(sport database units)),
    g('A3', qw(ones zeroes convert range)),
    g('A4', qw(sum)),
    g('A5', qw(arith div_mod_10 div_mod_rotate)),
    g('A6', qw(count_by_sign find_min_max count_odd_even alg_min_max alg_avg)),
    g('A7', qw(names animals random_sequences)),
    g('A8', qw(equiv_3 equiv_4)),
    g('A9', qw(truth_table_fragment)),
    g('A10', qw(graph_by_matrix)),
]}

1;
