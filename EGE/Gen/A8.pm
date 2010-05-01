package EGE::Gen::A8;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Logic;

sub tts { EGE::Logic::truth_table_string($_[0], qw(A B C)) }

sub rand_expr_text {
    my $e = EGE::Logic::random_logic_expr_3(qw(A B C));
    ($e, $e->to_lang_named('Logic'));
}

sub equiv {
    my ($e, $e_text) = rand_expr_text;
    my $e_tts = tts($e);
    my %seen = ($e_text => 1);
    my (@good, @bad);
    until (@good && @bad >= 3) {
        my ($e1, $e1_text);
        do { ($e1, $e1_text) = rand_expr_text; } while $seen{$e1_text}++;
        tts($e1) eq $e_tts ? push @good, $e1_text : push @bad, $e1_text;
    }
    {
        question => "Укажите, какое логическое выражение равносильно выражению $e_text.",
        variants => [ $good[0], @bad[0..2] ],
        answer => 0,
        variants_order => 'random',
    };
}

1;
