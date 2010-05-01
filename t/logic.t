use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use lib '..';
use EGE::Prog qw(make_expr);
use EGE::Logic;

{
    my @t = (
        { e => 0, r => '0', c => 0 },
        { e => [ '&&', 1, 'a' ], r => '01', c => 1 },
        { e => [ '=>', 'a', 'b' ], r => '1011', c => 2 },
        { e => [ '^', 'a', [ '^', 'b', 'x' ] ], r => '01101001', c => 3 },
    );

    for (@t) {
        my $e = make_expr($_->{e});
        is EGE::Logic::truth_table_string($e), $_->{r}, "$_->{c} vars";
    }

}
