# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
use strict;
use warnings;

use Carp;
$SIG{__WARN__} = sub { Carp::confess @_ };
$SIG{__DIE__} = sub { Carp::confess @_ };
$SIG{INT} = sub { Carp::confess @_ };

use Data::Dumper;
use Encode;
use List::Util 'min';

use lib '.';

use EGE::Generate;
use EGE::Math::Summer;
use EGE::Random;


my $questions;

sub g { push @$questions, EGE::Generate::g(@_); }

sub print_dump {
    for (@$questions) {
        my $dump = Dumper($_);
        Encode::from_to($dump, 'UTF8', 'CP866');
        print $dump;
    }
}

sub print_html {
    print q~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ru" xml:lang="ru">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <style type="text/css">li.correct { color: red; }</style>
</head>
<body>
~;
    for my $q (@$questions) {
        print qq~
<div>
$q->{text}
<ol>
~;
        my (@v, $correct);
        if ($q->{type} eq 'sc') {
            @v = @{$q->{variants}};
            $correct = $q->{correct}
        }
        else {
            @v = ($q->{correct});
            $correct = 0;
        }
        my $i = 0;
        for (@v) {
            my $style = $i++ == $correct ? ' class="correct"' : '';
            print "<li$style>$_</li>\n";
        }
        print "</ol>\n</div>\n";
    }
    print "</body>\n</html>";
}

sub quote {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\n/\\n/g;
    $s =~ /^\d+$/ ? $s : qq~"$s"~;
}

sub print_json {
    print "[\n";
    for my $q (@$questions) {
        print '{';
        print
            join ', ', map qq~"$_":~ . quote($q->{$_}), qw(type text correct);
        print ', "variants": [', join(', ', map quote($_), @{$q->{variants}}), '], '
            if $q->{variants};
        print " },\n";
    }
    print "]\n";
}

binmode STDOUT, ':utf8';

my %all_tasks = (
    A => [
        ['01', 'recode'],
        ['01', 'simple'],
        ['02', 'sport'],
        ['02', 'car_numbers'],
        ['02', 'database'],
        ['02', 'units'],
        ['02', 'min_routes'],
        ['03', 'ones'],
        ['03', 'zeroes'],
        ['03', 'convert'],
        ['03', 'range'],
        ['04', 'sum'],
        ['05', 'arith'],
        ['05', 'div_mod_10'],
        ['05', 'div_mod_rotate'],
        ['05', 'digit_by_digit'],
        ['06', 'count_by_sign'],
        ['06', 'find_min_max'],
        ['06', 'count_odd_even'],
        ['06', 'alg_min_max'],
        ['06', 'alg_avg'],
        ['06', 'bus_station'],
        ['07', 'names'],
        ['07', 'animals'],
        ['07', 'random_sequences'],
        ['07', 'restore_password'],
        ['07', 'spreadsheet_shift'],
        ['08', 'equiv_3'],
        ['08', 'equiv_4'],
        ['08', 'audio_sampling'],
        ['09', 'truth_table_fragment'],
        ['09', 'find_var_len_code'],
        ['10', 'graph_by_matrix'],
        ['11', 'variable_length'],
        ['11', 'fixed_length'],
        ['11', 'password_length'],
        ['12', 'beads'],
        ['12', 'array_flip'],
        ['13', 'file_mask'],
        ['13', 'file_mask2'],
        ['13', 'file_mask3'],
        ['14', 'database'],
        ['15', 'rgb'],
        ['16', 'spreadsheet'],
        ['17', 'diagram'],
        ['18', 'robot_loop'],
    ],
    B => [
        ['01', 'direct'],
        ['01', 'recode2'],
        ['02', 'flowchart'],
        ['03', 'q1234'],
        ['03', 'last_digit'],
        ['03', 'count_digits'],
        ['04', 'impl_border'],
        ['04', 'lex_order'],
        ['05', 'calculator'],
        ['05', 'complete_spreadsheet'],
        ['06', 'solve'],
        ['07', 'who_is_right'],
        ['08', 'identify_letter'],
        ['08', 'find_calc_system'],
        ['11', 'ip_mask'],
        ['12', 'search_query'],
        ['13', 'plus_minus'],
        ['15', 'logic_var_set'],
    ]
);

my %new_tasks = (
    A => [
        ['02', 'min_routes'],
        ['05', 'digit_by_digit'],
        ['07', 'spreadsheet_shift'],
        ['08', 'audio_sampling'],
        ['09', 'find_var_len_code'],
        ['11', 'password_length'],
        ['12', 'array_flip'],
    ],
    B => [
        ['01', 'recode2'],
        ['04', 'lex_order'],
        ['05', 'complete_spreadsheet'],
        ['08', 'find_calc_system'],
        ['11', 'ip_mask'],
        ['12', 'search_query'],
        ['13', 'plus_minus'],
        ['15', 'logic_var_set'],
    ]
);

my %old_tasks = (
    A => [
        ['01', 'recode'],
        ['01', 'simple'],
        ['02', 'sport'],
        ['02', 'car_numbers'],
        ['02', 'database'],
        ['02', 'units'],
        ['03', 'ones'],
        ['03', 'zeroes'],
        ['03', 'convert'],
        ['03', 'range'],
        ['04', 'sum'],
        ['05', 'arith'],
        ['05', 'div_mod_10'],
        ['05', 'div_mod_rotate'],
        ['06', 'count_by_sign'],
        ['06', 'find_min_max'],
        ['06', 'count_odd_even'],
        ['06', 'alg_min_max'],
        ['06', 'alg_avg'],
        ['06', 'bus_station'],
        ['07', 'names'],
        ['07', 'animals'],
        ['07', 'random_sequences'],
        ['07', 'restore_password'],
        ['08', 'equiv_3'],
        ['08', 'equiv_4'],
        ['09', 'truth_table_fragment'],
        ['10', 'graph_by_matrix'],
        ['11', 'variable_length'],
        ['11', 'fixed_length'],
        ['12', 'beads'],
        ['13', 'file_mask'],
        ['13', 'file_mask2'],
        ['13', 'file_mask3'],
        ['14', 'database'],
        ['15', 'rgb'],
        ['16', 'spreadsheet'],
        ['17', 'diagram'],
        ['18', 'robot_loop'],
    ],
    B => [
        ['01', 'direct'],
        ['02', 'flowchart'],
        ['03', 'q1234'],
        ['03', 'last_digit'],
        ['03', 'count_digits'],
        ['04', 'impl_border'],
        ['05', 'calculator'],
        ['06', 'solve'],
        ['07', 'who_is_right'],
        ['08', 'identify_letter'],
    ]
);

sub g_num {
    my ($unit, $gen, $num) = ($_[0] . $_[1], $_[2], $_[3]);
    my $q = EGE::Generate::one($unit, $gen);
    if ($num) {
        my $head = sprintf("%s%02d", $_[0], $num);
        $q->{text} = "<h3>$head</h3>\n$q->{text}";
    }
    $q
}

sub full_random {
    my ($a_cnt, $b_cnt) = @_;
    my $i = 0;
    for (rnd->pick_n($a_cnt, @{$all_tasks{A}})) {
        push @$questions, g_num('A', @$_, ++$i);
    }
    my $j = 0;
    for (rnd->pick_n($b_cnt, @{$all_tasks{B}})) {
        push @$questions, g_num('B', @$_, ++$j);
    }
}

sub new_tasks_first {
    my ($a_cnt, $b_cnt) = @_;
    my ($na_cnt, $nb_cnt) = (int @{$new_tasks{A}}, int @{$new_tasks{B}});
    my (@a, @b);
    for (rnd->pick_n(min($a_cnt, $na_cnt), @{$new_tasks{A}})) {
        push @a, g_num('A', @$_);
    }
    for (rnd->pick_n($a_cnt - $na_cnt, @{$old_tasks{A}})) {
        push @a, g_num('A', @$_);
    }
    for (rnd->pick_n(min($b_cnt, $nb_cnt), @{$new_tasks{B}})) {
        push @b, g_num('B', @$_);
    }
    for (rnd->pick_n($b_cnt - $nb_cnt, @{$old_tasks{B}})) {
        push @b, g_num('B', @$_);
    }
    @a = rnd->shuffle(@a);
    @b = rnd->shuffle(@b);
    for my $i (0 .. $#a) {
        $a[$i]->{text} = sprintf("<h3>A%d</h3>\n%s", $i + 1, $a[$i]->{text});
    }
    for my $j (0 .. $#b) {
        $b[$j]->{text} = sprintf("<h3>B%d</h3>\n%s", $j + 1, $b[$j]->{text});
    }
    $questions = [@a, @b];
}

#$questions = EGE::Generate::all;
#push @$questions, EGE::Math::Summer::g($_) for qw(p1 p2 p3 p4 p5 p6 p7);

#full_random(15, 10);
new_tasks_first(15, 10);

print_html;
#print_json;
