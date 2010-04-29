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

1;
