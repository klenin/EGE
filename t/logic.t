use strict;
use warnings;
use utf8;

use Test::More tests => 3;

use lib '..';
use EGE::Prog qw(make_expr);
use EGE::Logic;

{
    my $e = make_expr(0);
    is EGE::Logic::truth_table_string($e), '0', '0 vars';
}

{
    my $e = make_expr([ '&&', 1, 'a' ]);
    is EGE::Logic::truth_table_string($e, 'a'), '01', '1 var';
}

{
    my $e = make_expr([ '=>', 'a', 'b' ]);
    is EGE::Logic::truth_table_string($e, 'b', 'a'), '1101', '2 vars';
}
