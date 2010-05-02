use strict;
use warnings;
use utf8;

use Test::More tests => 10;

use lib '..';
use EGE::Prog qw(make_expr);
use EGE::Logic;

sub tts { EGE::Logic::truth_table_string($_[0]) }

{
    my @t = (
        { e => 0, r => '0', c => 0 },
        { e => [ '&&', 1, 'a' ], r => '01', c => 1 },
        { e => [ '=>', 'a', 'b' ], r => '1011', c => 2 },
        { e => [ '^', 'a', [ '^', 'b', 'x' ] ], r => '01101001', c => 3 },
    );

    is tts(make_expr($_->{e})), $_->{r}, "$_->{c} vars" for @t;
}

{
    my @t = (
        {
            e => 'a',
            r => [ '!', [ '!', 'a' ] ],
        },
        {
            e => [ '&&', 'a', 'b' ],
            r => [ '!', [ '||', [ '!', 'a' ], [ '!', 'b' ] ] ],
        },
        {
            e => [ '!', [ '=>', 'a', 'b' ] ],
            r => [ '&&', 'a', [ '!', 'b' ] ],
        },
    );
    for (@t) {
        my $e = make_expr($_->{e});
        my $e_text = $e->to_lang_named('Pascal');
        my $e1 = EGE::Logic::equiv_not($e);
        is_deeply $e1, make_expr($_->{r}), "equiv_not $e_text";
        is tts($e), tts($e1), "tts equiv_not $e_text";
    }
}
