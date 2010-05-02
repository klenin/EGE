
use strict;
use warnings;

use Data::Dumper;
use Encode;

use lib '.';

use EGE::Generate;

use EGE::Gen::A01;
use EGE::Gen::A02;
use EGE::Gen::A03;
use EGE::Gen::A04;
use EGE::Gen::A05;
use EGE::Gen::A06;
use EGE::Gen::A07;
use EGE::Gen::A08;
use EGE::Gen::A09;

my $questions;

sub g { push @$questions, EGE::Generate::one(@_); }

sub print_dump {
    for (@$questions) {
        my $dump = Dumper($_);
        Encode::from_to($dump, 'UTF8', 'CP866');
        print $dump;
    }
}

sub print_html {
    print q~<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
~;
    for my $q (@$questions) {
        print qq~
<div>
<p>$q->{question}</p>
<ol>
~;
        my $i = 0;
        for (@{$q->{variants}}) {
            my $style = $i++ == $q->{answer} ? ' style="color:red"' : '';
            print "<li$style>$_</li>\n";
        }
        print "</ol>\n";
    }
    print "</body>\n";
}

binmode STDOUT, ':utf8';

#g('A1', 'recode');
#g('A1', 'simple');
#g('A2', 'sport');
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
#g('A6', 'find_min_max');
#g('A6', 'count_odd_even');
#g('A6', 'alg_min_max');
#g('A6', 'alg_avg');
#g('A7', 'names');
#g('A7', 'animals');
#g('A7', 'random_sequences');
#g('A8', 'equiv_3');
#g('A8', 'equiv_4');
g('A9', 'truth_table_fragment');

print_html;
