
use strict;
use warnings;

use Data::Dumper;
use Encode;

use lib '.';

use EGE::Gen::A1;
use EGE::Gen::A2;
use EGE::Gen::A3;
use EGE::Gen::A4;
use EGE::Gen::A5;

my @questions;

sub g {
    no strict 'refs';
    push @questions, "EGE::Gen::$_[0]::$_[1]"->();
}

sub print_dump {
    for (@questions) {
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
    for my $q (@questions) {
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
g('A5', 'arith');
g('A5', 'div_mod');
print_html;
