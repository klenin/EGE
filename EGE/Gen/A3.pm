package EGE::Gen::A3;

use strict;
use warnings;

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

1;
