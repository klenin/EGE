# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A03;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bin;
use EGE::Bits;

sub ones {
    my ($self) = @_;
    my $npower = rnd->in_range(5, 10);
    my $case = rnd->pick(
        { d => 0, a => 0 }, { d => 1, a => 1 }, { d => -1, a => 3 },
    );
    my $n = 2 ** $npower + $case->{d};

    $self->{text} = "Сколько единиц в двоичной записи числа $n?";
    $self->variants(1, 2, $npower - 1, $npower);
    $self->{correct} = $case->{a};
}

sub zeroes {
    my ($self) = @_;
    my $bits = [ 1, map(rnd->coin, 1..6), 0 ];
    my $nzeroes = grep !$_, @$bits;
    my $n = EGE::Bits->new->set_bin($bits, 1)->get_dec;
    $self->{text} = "Сколько значащих нулей в двоичной записи числа $n?";
    $self->variants($nzeroes, $nzeroes + 1, $nzeroes + 2, $nzeroes - 1);
}

sub convert {
    my ($self) = @_;
    my $n = 32 + rnd->in_range(0, 15) * 2 + 1;
    my $v = EGE::Bits->new->set_size(7)->set_dec($n);
    my $bin = substr($v->get_bin, 1);
    
    my $rn = int($v->dup->reverse_->shift_(-1)->get_dec);
    my $fn = int($v->dup->flip(rnd->in_range(0, 5))->get_dec);

    my %seen = ($n => 1);
    my @errors = grep !$seen{$_}++,
        $n * 2, int($n / 2), $n + 1, $n - 1, $rn, $rn + 1, $rn - 1, $fn;
    $self->{text} = "Переведите число $bin<sub>2</sub> в десятичную систему.",
    $self->variants($n, rnd->pick_n(3, @errors));
}

sub range {
    my ($self) = @_;
    my $av = rnd->in_range(1, 13);
    my $bv = rnd->in_range(2, 15 - $av);
    $av += rnd->in_range(1, 16) * 16;
    $bv += $av;
    my $x = rnd->in_range($av + 1, $bv - 1);

    my ($atext, $btext) = map hex_or_oct($_, rnd->coin), $av, $bv;
    $self->{text} =
        "Дано: <i>a</i> = $atext, <i>b</i> = $btext. " .
        'Какое из чисел <i>x</i>, записанных в двоичной системе, отвечает ' .
        'неравенству <i>a</i> &lt; <i>x</i> &lt; <i>b</i>?';
    my @bits = map 1 << $_, 0..7;
    my @errors = (
        $av, $bv,
        map($av - $_, grep $_ & $av, @bits),
        map($bv + $_, grep !($_ & $bv), @bits),
    );
    $self->variants(map to_bin($_), $x, rnd->pick_n(3, @errors));
}

1;
