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
use EGE::Gen::B06;
use EGE::Gen::B07;
use EGE::Gen::B08;
use EGE::Gen::B11;
use EGE::Gen::B12;
use EGE::Gen::B13;
use EGE::Gen::B15;

use EGE::Gen::Arch01;
use EGE::Gen::Arch02;
use EGE::Gen::Arch03;
use EGE::Gen::Arch04;

sub one {
    my ($package, $method) = @_;
    no strict 'refs';
    local $_;
    my $g = "EGE::Gen::$package"->new;
    $g->$method;
    $g->post_process;
    $g;
}

sub g {
    my $unit = shift;
    my ($p, $n) = ($unit =~ /^(\w+)(\d+)$/);
    my $q = one sprintf('%s%02d', $p, $n), rnd->pick(@_);
    $q->{text} = "<h3>$unit</h3>\n$q->{text}";
    $q;
}

sub gg {
    my $unit = shift;
    map g($unit, $_), @_;
}

sub all {[
    gg('A1', qw(recode simple)),
    gg('A2', qw(sport car_numbers database units min_routes)),
    gg('A3', qw(ones zeroes convert range)),
    gg('A4', qw(sum)),
    gg('A5', qw(arith div_mod_10 div_mod_rotate digit_by_digit)),
    gg('A6', qw(count_by_sign find_min_max count_odd_even alg_min_max alg_avg bus_station)),
    gg('A7', qw(names animals random_sequences restore_password spreadsheet_shift)),
    gg('A8', qw(equiv_3 equiv_4 audio_sampling)),
    gg('A9', qw(truth_table_fragment find_var_len_code)),
    gg('A10', qw(graph_by_matrix)),
    gg('A11', qw(variable_length fixed_length password_length)),
    gg('A12', qw(beads array_flip)),
    gg('A13', qw(file_mask file_mask2 file_mask3)),
    gg('A14', qw(database)),
    gg('A15', qw(rgb)),
    gg('A16', qw(spreadsheet)),
    gg('A17', qw(diagram)),
    gg('A18', qw(robot_loop)),
    gg('B01', qw(direct recode2)),
    gg('B02', qw(flowchart)),
    gg('B03', qw(q1234 last_digit count_digits)),
    gg('B04', qw(impl_border lex_order)),
    gg('B05', qw(calculator complete_spreadsheet)),
    gg('B06', qw(solve)),
    gg('B07', qw(who_is_right)),
    gg('B08', qw(identify_letter find_calc_system)),
    gg('B11', qw(ip_mask)),
    gg('B12', qw(search_query)),
    gg('B13', qw(plus_minus)),
    gg('B15', qw(logic_var_set)),
]}

1;
