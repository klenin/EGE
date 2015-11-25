# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A04;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bin;
use EGE::Bits;
use EGE::NumText;

sub sum {
    my ($self) = @_;
    my $av = rnd->in_range(17, 127);
    my $bv = rnd->in_range(17, 127);
    my $r = $av + $bv;
    my ($atext, $btext) = map hex_or_oct($_), $av, $bv;
    $self->{text} = "Чему равна сумма чисел <i>a</i> = $atext и <i>b</i> = $btext?";
    my @errors = rnd->pick_n(3, map $av ^ (1 << $_), 0..7);
    $self->variants(map bin_hex_or_oct($_, rnd->in_range(0, 2)), $r, @errors);
}

sub _generate_by_count {
    my($val, $size, $count) = @_;
    EGE::Bits->new->
        set_bin([ 1, (1 - $val) x ($size - 1) ], 1)->
        flip(rnd->pick_n($count - $val, 0 .. $size - 2))->
        get_dec;
}

sub count_zero_one {
    my ($self) = @_;
    my $val = rnd->coin;
    my $num_size = rnd->in_range(7, 10);
    my $count = rnd->in_range(2, $num_size - 4);

    $self->variants(map _generate_by_count($val, $num_size, $count + $_), 0..2, -1);

    $self->{text} = sprintf
        'Для каждого из перечисленных ниже десятичных чисел построили двоичную запись. ' .
        'Укажите число, двоичная запись которого содержит ровно %s.',
        num_text($count, $val ?
            [ 'единица', 'единицы', 'единиц' ] :
            [ 'значащий нуль', 'значащих нуля', 'значащих нулей' ]);
}

1;
