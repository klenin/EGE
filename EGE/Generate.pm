# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

use strict;
use warnings;
use utf8;

package EGE::GenerateBase;

use EGE::Random;

our $test = sub {};

sub one {
    my ($package, $method) = @_;
    no strict 'refs';
    local $_;
    my $g = "EGE::Gen::$package"->new;
    $g->$method;
    $g->post_process;
    $g->{method} = $method;
    $test->($g);
    $g;
}

package EGE::Generate;

use EGE::Random;

use EGE::GenBase;
use EGE::Gen::EGE::A01;
use EGE::Gen::EGE::A02;
use EGE::Gen::EGE::A03;
use EGE::Gen::EGE::A04;
use EGE::Gen::EGE::A05;
use EGE::Gen::EGE::A06;
use EGE::Gen::EGE::A07;
use EGE::Gen::EGE::A08;
use EGE::Gen::EGE::A09;
use EGE::Gen::EGE::A10;
use EGE::Gen::EGE::A11;
use EGE::Gen::EGE::A12;
use EGE::Gen::EGE::A13;
use EGE::Gen::EGE::A14;
use EGE::Gen::EGE::A15;
use EGE::Gen::EGE::A16;
use EGE::Gen::EGE::A17;
use EGE::Gen::EGE::A18;
use EGE::Gen::EGE::B01;
use EGE::Gen::EGE::B02;
use EGE::Gen::EGE::B03;
use EGE::Gen::EGE::B04;
use EGE::Gen::EGE::B05;
use EGE::Gen::EGE::B06;
use EGE::Gen::EGE::B07;
use EGE::Gen::EGE::B08;
use EGE::Gen::EGE::B10;
use EGE::Gen::EGE::B11;
use EGE::Gen::EGE::B12;
use EGE::Gen::EGE::B13;
use EGE::Gen::EGE::B14;
use EGE::Gen::EGE::B15;
use EGE::Gen::EGE::Z06;
use EGE::Gen::EGE::Z09;
use EGE::Gen::EGE::Z10;
use EGE::Gen::EGE::Z11;
use EGE::Gen::EGE::Z12;
use EGE::Gen::EGE::Z13;
use EGE::Gen::EGE::Z15;
use EGE::Gen::EGE::Z16;
use EGE::Gen::EGE::Z18;
use EGE::Gen::EGE::Z22;

sub g {
    my $unit = shift;
    my ($p, $n) = ($unit =~ /^([A-Za-z]+)(\d+)$/);
    my $q = EGE::GenerateBase::one( sprintf('EGE::%s%02d', $p, $n), rnd->pick(@_) );
    $q->{text} = "<h3>$unit</h3>\n$q->{text}";
    $q;
}

sub gg {
    my $unit = shift;
    map g($unit, $_), @_;
}

sub all {[
    gg('A1', qw(recode simple)),
    gg('A2', qw(sport car_numbers database units min_routes sport_athlete)),
    gg('A3', qw(ones zeroes convert range binary_num_system)),
    gg('A4', qw(sum)),
    gg('A4', qw(count_zero_one)),
    gg('A5', qw(arith div_mod_10 div_mod_rotate digit_by_digit crc)),
    gg('A6', qw(count_by_sign find_min_max count_odd_even alg_min_max alg_avg bus_station crc_message inf_size)),
    gg('A7', qw(names animals random_sequences restore_password spreadsheet_shift)),
    gg('A8', qw(equiv_3 equiv_4 audio_size audio_time)),
    gg('A9', qw(truth_table_fragment find_var_len_code error_correction_code hamming_code)),
    gg('A10', qw(graph_by_matrix light_panel min_alphabet)),
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
    gg('B02', qw(simple_while)),
    gg('B03', qw(q1234 last_digit last_digit_base count_digits count_ones music_time_to_time music_size_to_size music_format_time_to_time select_base move_number range_count)),
    gg('B03', qw(simple_equation min_required_base)),
    gg('B04', qw(impl_border lex_order morse bulbs plus_minus letter_combinatorics signal_rockets how_many_sequences1 how_many_sequences2)),
    gg('B05', qw(calculator complete_spreadsheet adsl_speed)),
    gg('B06', qw(solve recursive_function password_meta)),
    gg('B07', qw(who_is_right)),
    gg('B08', qw(identify_letter find_calc_system first_sum_digits)),
    gg('B10', qw(trans_rate trans_time trans_latency min_period_of_time trans_text trans_time_size)),
    gg('B11', qw(ip_mask subnet_mask)),
    gg('B12', qw(search_query)),
    gg('B13', qw(plus_minus)),
    gg('B14', qw(find_func_min)),
    gg('B15', qw(logic_var_set)),
    gg('Z06', qw(find_number min_add_digits grasshopper)),
    gg('Z09', qw(get_memory_size)),
    gg('Z10', qw(words_count)),
    gg('Z11', qw(recursive_alg)),
    gg('Z12', qw(ip_computer_number)),
    gg('Z13', qw(tumblers tumblers_min young_spy)),
    gg('Z15', qw(city_roads)),
    gg('Z16', qw(base_gcd)),
    gg('Z18', qw(bitwise_conjunction)),
    gg('Z22', qw(calculator_find_prgm_count)),
]}

package EGE::AsmGenerate;

use EGE::Random;

use EGE::GenBase;
use EGE::Gen::Arch::Arch01;
use EGE::Gen::Arch::Arch02;
use EGE::Gen::Arch::Arch03;
use EGE::Gen::Arch::Arch04;
use EGE::Gen::Arch::Arch05;
use EGE::Gen::Arch::Arch06;
use EGE::Gen::Arch::Arch07;
use EGE::Gen::Arch::Arch08;
use EGE::Gen::Arch::Arch09;
use EGE::Gen::Arch::Arch10;
use EGE::Gen::Arch::Arch12;
use EGE::Gen::Arch::Arch13;

sub g {
    my $unit = shift;
    my $q = EGE::GenerateBase::one("Arch::$unit", rnd->pick(@_));
    $q;
}

sub gg {
    my $unit = shift;
    map g($unit, $_), @_;
}

sub all {[
    gg('Arch01', qw(reg_value_add reg_value_logic reg_value_bscan reg_value_shift reg_value_convert reg_value_jump reg_value_div)),
    gg('Arch02', qw(flags_value_add flags_value_logic flags_value_shift)),
    gg('Arch03', qw(choose_commands_mod_3)),
    gg('Arch04', qw(choose_commands)),
    gg('Arch05', qw(sort_commands sort_commands_stack)),
    gg('Arch06', qw(match_values)),
    gg('Arch07', qw(loop_number)),
    gg('Arch08', qw(choose_jump)),
    gg('Arch09', qw(reg_value_before_loopnz zero_fill stack)),
    gg('Arch10', qw(jcc_check_flags cmovcc)),
    gg('Arch12', qw(cond_max_min divisible_by_mask)),
    gg('Arch13', qw(expression_calc)),
]}

package EGE::DatabaseGenerate;

use EGE::Random;

use EGE::GenBase;
use EGE::Gen::Db::Db01;
use EGE::Gen::Db::Db02;
use EGE::Gen::Db::Db03;
use EGE::Gen::Db::Db04;
use EGE::Gen::Db::Db05;
use EGE::Gen::Db::Db06;
use EGE::Gen::Db::Db07;
use EGE::Gen::Db::Db08;
use EGE::Gen::Db::Db09;
use EGE::Gen::Db::Db10;
use EGE::Gen::Db::Db11;
use EGE::Gen::Db::Db12;
use EGE::Gen::Db::Db13;


sub g {
    my ($p, $m) = @_;
    EGE::GenerateBase::one("Db::$p", $m);
}

sub gg {
    my $unit = shift;
    map g($unit, $_), @_;
}

sub all {[
    gg('Db01', qw(trivial_select trivial_delete)),
    gg('Db02', qw(select_where)),
    gg('Db03', qw(trivial_update)),
    gg('Db04', qw(choose_update)),
    gg('Db05', qw(insert_delete)),
    gg('Db06', qw(select_between select_expression)),
    gg('Db07', qw(trivial_inner_join)),
    gg('Db08', qw(parents grandchildren nuncle)),
    gg('Db09', qw(inner_join)),
    gg('Db10', qw(many_inner_join)),
    gg('Db11', qw(inner_join_count trivial_aggregate_func)),
    gg('Db12', qw(create_nested_query)),
    gg('Db13', qw(trivial_group_by group_by_having)),
]}

package EGE::AlgGenerate;

use EGE::GenBase;
use EGE::Gen::Alg::Complexity;
use EGE::Gen::Alg::CallCount;
use EGE::Gen::Alg::Tree;
use EGE::Gen::Alg::Graph;
use EGE::Gen::Alg::List;
use EGE::Gen::Alg::Sorting;

sub g {
    my ($p, $m) = @_;
    EGE::GenerateBase::one("Alg::$p", $m);
}

sub gg {
    my $unit = shift;
    map g($unit, $_), @_;
}

sub all {[
    gg('Complexity', qw(o_poly o_poly_cmp complexity substitution amortized)),
    gg('Complexity::ComplexityDI', qw(cycle_complexity)),
    gg('CallCount', qw(super_recursion)),
    gg('Tree', qw(node_count height)),
    gg('Graph', qw(graph_seq)),
    gg('List', qw(construct_command)),
    gg('Sorting', qw(sort_line)),
]}

1;
