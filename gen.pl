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

use lib '.';

use EGE::Generate;
use EGE::Math::Summer;

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

#g('A1', 'recode');
#g('A1', 'simple');
#g('A2', 'sport');
#g('A2', 'car_numbers');
#g('A2', 'database');
#g('A2', 'units');
#g('A3', 'ones');
#g('A3', 'zeroes');
#g('A3', 'convert');
#g('A3', 'range');
#g('A4', 'sum');
#g('A5', 'arith');
#g('A5', 'div_mod_10');
#g('A5', 'div_mod_rotate');
#g('A6', 'count_by_sign');
#g('A6', 'bus_station');
#g('A6', 'find_min_max');
#g('A6', 'count_odd_even');
#g('A6', 'alg_min_max');
#g('A6', 'alg_avg');
#g('A7', 'names');
#g('A7', 'animals');
#g('A7', 'random_sequences');
#g('A8', 'equiv_3');
#g('A8', 'equiv_4');
#g('A9', 'truth_table_fragment');
#g('A10', 'graph_by_matrix');
#g('A11', 'variable_length');
#g('A11', 'fixed_length');
#g('A12', 'beads');
#g('A13', 'file_mask');
#g('A14', 'database');
#g('A15', 'rgb');
#g('A16', 'spreadsheet');
#g('A17', 'diagram');
#g('A18', 'robot_loop');
#g('B01', 'direct');
#g('B02', 'flowchart');
#g('B03', 'q1234');
#g('B03', 'last_digit');
#g('B03', 'count_digits');
#g('B04', 'impl_border');
#g('B05', 'calculator');
$questions = EGE::Generate::all;

#push @$questions, EGE::Math::Summer::g($_) for qw(p1 p2 p3 p4 p5 p6 p7);

print_html;
#print_json;
