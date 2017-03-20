use strict;
use warnings;

use Test::More tests => 29;
use Test::Exception;

use Config;
use List::Util qw(sum);

use lib '..';
use EGE::Random;

is scalar(grep 1 <= $_ && $_ <= 10, map rnd->in_range(1, 10), 1..99), 99, 'in_range';

throws_ok { rnd->in_range(1..10); } qr/arguments/, 'in_range(1..10)';
throws_ok { rnd->in_range(1, 0) } qr/</, 'in_range empty';

is rnd->in_range_except(1, 2, 1), 2, 'in_range_except';
is rnd->in_range_except(1, 4, [1, 2, 3]), 4, 'in_range_except many';

{
    my @cnt;
    @cnt[rnd->in_range_except(1, 7, [1, 3, 4, 6])]++ for 1 .. 3000;
    is_deeply [ grep $cnt[$_], 0 .. $#cnt ], [2, 5, 7], 'in_range_except historgam 1';
    is scalar(grep $_ && abs($_ - 1000) > 99, @cnt), 0, 'in_range_except historgam 2';
}

like rnd->coin, qr/^0|1$/, 'coin';

is rnd->pick(99), 99, 'pick 1';
like rnd->pick('a' .. 'z'), qr/^[a-z]$/, 'pick';

{
    my @v = rnd->pick_n(2, 'a' .. 'z');
    ok @v == 2 && $v[0] ne $v[1] && join('', @v) =~ /^[a-z]{2}$/, 'pick_n few';
    @v = rnd->pick_n(25, 'a' .. 'z');
    ok @v == 25 && join('', @v) =~ /^[a-z]{25}$/, 'pick_n many';
    @v = rnd->shuffle('a' .. 'z');
    ok @v == 26 && join('', sort @v) =~ join('', 'a' .. 'z'), 'shuffle';
}

subtest pick_except => sub {
    plan tests => 6;
    my @r = 'a'..'d';
    for (1..3) {
        my $p = rnd->pick(@r);
        my $v = rnd->pick_except($p, @r);
        ok $v =~ /^[a-d]$/, "in $_";
        isnt $v, $p, "out $_";
    }
};

throws_ok { rnd->pick() } qr/empty/, 'pick from empty';
throws_ok { rnd->pick_n(3, 1, 2) } qr/^pick_n/, 'pick_n too many';
throws_ok { rnd->pick_except(3) } qr/except/, 'except nothing';

{
    my ($v1, $v2, $v3) = rnd->pick_n_sorted(3, 'a' .. 'z');
    ok $v1 lt $v2 && $v2 lt $v3 && "$v1$v2$v3" =~ /^[a-z]{3}$/, 'pick_n_sorted';
}

{
    my @v = rnd->split_number(20, 3);
    ok @v == 3 && 3 == grep($_ > 0, @v) && sum(@v) == 20, 'split_number';
}

{
    my $v = rnd->get_letter_from_string('qw');
    ok $v eq 'q' || $v eq 'w' , 'get_letter_from_string';
}

SKIP: {
    skip '64-bit only', 1 if $Config{ivsize} < 8;
    my $rnd64 = EGE::Random->new(gen => 'PCG_XSH_RR_64_32');
    my $rnd32 = EGE::Random->new(gen => 'PCG_XSH_RR_64_32_BigInt');
    my $seed = time;
    $rnd64->seed($seed, 444);
    $rnd32->seed($seed, 444);
    is scalar(grep $rnd32->in_range(0, 10000) != $rnd64->in_range(0, 10000), 1..10), 0, 'PCG BigInt';
}

sub histogram {
    my ($rnd, $range, $dim) = @_;
    my $h;
    $h->{join '#', map $rnd->in_range(1, $range), 1..$dim}++ for 1..($range ** $dim) * 10;
    cmp_ok $range ** $dim - keys(%$h), '<=', 1, "$dim-D histogram";
}

histogram(rnd, 7, 2);
histogram(rnd, 6, 3);
histogram(rnd, 5, 4);

is(EGE::Random->new->seed(999, 888)->in_range(0, 1 << 31), 2034720810, 'stable from seed');
isnt(EGE::Random->new->in_range(0, 1 << 31), EGE::Random->new->in_range(0, 1 << 31), 'unique');

{
    my $r1 = EGE::Random->new;
    my @ss = $r1->get_seed;
    my $r2 = EGE::Random->new->seed(@ss);
    is $r1->in_range(1, 1000000), $r2->in_range(1, 1000000), "get_seed $_" for 1..3;
}

1;
