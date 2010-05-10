# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A09;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bits;
use EGE::Logic;
use EGE::Html;

sub rand_expr_text {
    my $e = EGE::Logic::random_logic_expr(@_);
    ($e, $e->to_lang_named('Logic'));
}

sub tt_row {
    my ($e, $bits, @vars) = @_;
    my $r = EGE::Logic::bits_to_vars($bits, @vars);
    $r->{F} = $e->run($r);
    $r;
}

sub tt_html {
    my ($table, @vars) = @_;
    my $r = html->row_n('th', @vars);
    $r .= html->row_n('td', @$_{@vars}) for @$table;
    html->table($r, { border => 1 });
}

sub check_rows {
    my ($table, $e) = @_;
    for (@$table) {
        return 0 if $e->run($_) != $_->{F};
    }
    return 1;
}

sub truth_table_fragment {
    my @vars = qw(X Y Z);
    my ($e, $e_text) = rand_expr_text(@vars);
    my @rows = sort { $a <=> $b } rnd->pick_n(3, 0 .. 2 ** @vars - 1);
    my @bits = map EGE::Bits->new->set_size(4)->set_dec($_), @rows;
    my $fragment = [ map tt_row($e, $_, @vars), @bits ];
    my %seen = ($e_text => 1);
    my @bad;
    while (@bad < 3) {
        my ($e1, $e1_text);
        do {
            ($e1, $e1_text) = rand_expr_text(@vars);
        } while $seen{$e1_text}++;
        push @bad, $e1_text unless check_rows($fragment, $e1);
    }
    my $tt_text = tt_html($fragment, @vars, 'F');
    my $q =
        'Символом F обозначено одно из указанных ниже логических выражений ' .
        'от трёх аргументов X, Y, Z. ' .
        "Дан фрагмент таблицы истинности выражения F: \n$tt_text\n" .
        'Какое выражение соответствует F?';
    {
        question => $q,
        variants => [ $e_text, @bad ],
        answer => 0,
    };
}

1;
