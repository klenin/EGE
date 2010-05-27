use strict;
use warnings;

use Test::More tests => 5;

use lib '..';
use EGE::Random;

my $v;

$v = rnd->in_range(1, 10);
ok 1 <= $v && $v <= 10, 'in_range';

$v = rnd->coin;
ok $v == 0 || $v == 1, 'coin';

$v = rnd->pick('a' .. 'z');
ok $v =~ /^[a-z]$/, 'pick';

{
    my ($v1, $v2) = rnd->pick_n(2, 'a' .. 'z');
    ok $v1 ne $v2 && "$v1$v2" =~ /^[a-z]{2}$/, 'pick_n';
}

{
    my ($v1, $v2, $v3) = rnd->pick_n_sorted(3, 'a' .. 'z');
    ok $v1 lt $v2 && $v2 lt $v3 && "$v1$v2$v3" =~ /^[a-z]{3}$/, 'pick_n_sorted';
}

1;
