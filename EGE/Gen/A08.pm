# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A08;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Logic;

sub tts { EGE::Logic::truth_table_string($_[0]) }

sub rand_expr_text {
    my $e = EGE::Logic::random_logic_expr(@_);
    ($e, $e->to_lang_named('Logic'));
}

sub equiv_common {
    my @vars = @_;
    my ($e, $e_text) = rand_expr_text(@vars);
    my $e_tts = tts($e);
    my %seen = ($e_text => 1);
    my (@good, @bad);
    until (@good && @bad >= 3) {
        my ($e1, $e1_text);
        if (@bad > 300) {
            # случайный перебор может работать долго, поэтому
            # через некоторое время применяем эквивалентное преобразование
            $e1 = EGE::Logic::equiv_not($e);
            $e1_text = $e1->to_lang_named('Logic');
        }
        else {
            do {
                ($e1, $e1_text) = rand_expr_text(@vars);
            } while $seen{$e1_text}++;
        }
        tts($e1) eq $e_tts ? push @good, $e1_text : push @bad, $e1_text;
    }
    {
        question => "Укажите, какое логическое выражение равносильно выражению $e_text.",
        variants => [ $good[0], @bad[0..2] ],
        answer => 0,
    };
}

sub equiv_3 { equiv_common qw(A B C) }

sub equiv_4 { equiv_common qw(A B C D) }

1;
