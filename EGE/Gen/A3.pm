package EGE::Gen::A3;

use strict;
use warnings;

use Bit::Vector;
use EGE::Random;
use EGE::Bin;

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
    my $v = Bit::Vector->new_Dec(7, $n);
    my $bin = substr($v->to_Bin, 1);
    my $v1 = Bit::Vector->new(7);
    $v1->Reverse($v);
    $v1->Move_Right(1);
    my $rn = int($v1->to_Dec);
    $v1->Copy($v);
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

sub range {
    my $av = rnd->in_range(1, 13);
    my $bv = rnd->in_range(2, 15 - $av);
    $av += rnd->in_range(1, 16) * 16;
    $bv += $av;
    my $x = rnd->in_range($av + 1, $bv - 1);

    my ($atext, $btext) = map hex_or_oct($_, rnd->coin), $av, $bv;
    my $q = <<QUESTION
Дано: <i>a</i> = $atext, <i>b</i> = $btext.
Какое из чисел <i>x</i>, записанных в двоичной системе, отвечает
неравенству <i>a</i> &lt; <i>x</i> &lt; <i>b</i>?
QUESTION
;
    my @bits = map 1 << $_, 0..7;
    my @errors = (
        $av, $bv,
        map($av - $_, grep $_ & $av, @bits),
        map($bv + $_, grep !($_ & $bv), @bits),
    );
    {
        question => $q,
        variants => [ map to_bin($_), $x, rnd->pick_n(3, @errors) ],
        answer => 0,
        variants_order => 'random',
    };
}

1;
