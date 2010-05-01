package EGE::Logic;

use strict;
use warnings;
use utf8;

use EGE::Prog qw(make_expr);
use EGE::Random;

sub maybe_not { rnd->pick($_[0], [ '!', $_[0] ]) }

sub random_logic_expr_2 {
    my ($v1, $v2) = @_;
    make_expr([ rnd->pick(ops::logic), maybe_not($v1), maybe_not($v2) ]);
}

1;
