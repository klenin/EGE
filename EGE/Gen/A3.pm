package EGE::Gen::A3;

use strict;
use warnings;

use Bit::Vector;
use EGE::Random;

sub ones {
    my $npower = rnd->in_range(5, 9);
    my $case = rnd->pick(
        { d => 0, a => 0 }, { d => 1, a => 1 }, { d => -1, a => 2 },
    );
    my $n = 2 ** $npower + $case->{d};

    {
        question => "Сколько единиц в двоичной записи числа $n?",
        variants => [ 1, 2, $npower - 1, $npower ],
        answer => $case->{a},
        variants_order => 'random',
    };
}

sub zeroes {
    my $n = rnd->in_range(64, 127) * rnd->pick(2, 4);
    (my $nzeroes) = Bit::Vector->new_Dec(10, $n)->Interval_Scan_inc(0);
    {
        question => "Сколько значащих нулей двоичной записи числа $n?",
        variants => [ $nzeroes, $nzeroes + 1, $nzeroes + 2, $nzeroes - 1 ],
        answer => 0,
        variants_order => 'random',
    };
}

sub convert {
    my $n = 32 + rnd->in_range(0, 15) * 2 + 1;
    my $v = Bit::Vector->new_Dec(6, $n);
    my $bin = $v->to_Bin;
    my $v1 = Bit::Vector->new(6);
    $v1->Reverse($v);
    $v1->Resize(7);
    my $rn = int($v1->to_Dec);
    $v1->Copy($v);
    $v1->Bit_Off(6);
    $v1->bit_flip(rnd->in_range(0, 5));
    my $fn = int($v1->to_Dec);
    my %seen = ($n => 1);
    my @errors = grep !$seen{$_}++,
        $n * 2, int($n / 2), $n + 1, $n - 1, $rn, $rn + 1, $rn - 1, $fn;
    {
        question => "Переведите число $bin в десятичную систему.",
        variants => [ $n, rnd->pick_n(3, @errors) ],
        answer => 0,
        variants_order => 'random',
    };
}

1;
