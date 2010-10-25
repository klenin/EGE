# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Generate;

use strict;
use warnings;
use utf8;

use EGE::Random;

use EGE::GenBase;
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
use EGE::Gen::A11;
use EGE::Gen::A12;
use EGE::Gen::A13;
use EGE::Gen::A14;
use EGE::Gen::A15;
use EGE::Gen::A16;
use EGE::Gen::A17;
use EGE::Gen::A18;
use EGE::Gen::B01;
use EGE::Gen::B02;
use EGE::Gen::B03;
use EGE::Gen::B04;
use EGE::Gen::B05;

sub one {
    my ($package, $method) = @_;
    no strict 'refs';
    my $g = "EGE::Gen::$package"->new;
    $g->$method;
    $g->post_process;
    $g;
}

sub g {
    my $unit = shift;
    my ($p, $n) = ($unit =~ /^(\w)(\d+)$/);
    my $q = one sprintf('%s%02d', $p, $n), rnd->pick(@_);
    $q->{text} = "<h3>$unit</h3>\n$q->{text}";
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
    g('A6', qw(count_by_sign find_min_max count_odd_even alg_min_max alg_avg, bus_station)),
    g('A7', qw(names animals random_sequences)),
    g('A8', qw(equiv_3 equiv_4)),
    g('A9', qw(truth_table_fragment)),
    g('A10', qw(graph_by_matrix)),
    g('A11', qw(variable_length fixed_length)),
    g('A12', qw(beads)),
    g('A13', qw(file_mask)),
    g('A14', qw(database)),
    g('A15', qw(rgb)),
    g('A16', qw(spreadsheet)),
    g('A17', qw(diagram)),
    g('A18', qw(robot_loop)),
    g('B01', qw(direct)),
    g('B02', qw(flowchart)),
    g('B03', qw(q1234 last_digit count_digits)),
    g('B04', qw(impl_border)),
    g('B05', qw(calculator)),
]}

1;
