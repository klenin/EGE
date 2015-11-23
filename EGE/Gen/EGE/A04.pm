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

sub num_zero { num_text($_[0], [ 'значащий нуль', 'значащих нуля', 'значащих нулей' ]) }
sub num_one { num_text($_[0], [ 'единица', 'единицы', 'единиц' ]) }

sub generate_bin {
    my($val, $size, $cur_count) = @_;
    my $bin = EGE::Bits->new->set_size($size, $val);
    if ($val == 0) { $bin->flip($size - 1) } else { $cur_count-- };
    $bin->flip(rnd->pick_n($size - $cur_count - 1, 0..$size - 2));
    return $bin->get_dec;
}

sub count_zero_one {
    my ($self) = @_;
    my $z_o = rnd->coin;
    my $num_size = rnd->in_range(7, 11);
    my $count = rnd->in_range(2, $num_size - 4);
    my $type = $z_o == 1 ? num_one($count) : num_zero($count);

    my @variants_ar;
    for (my $i = 0; $i < 4; $i++){
        @variants_ar[$i] = generate_bin($z_o, $num_size, $count + $i);
    }

    $self->{text} = <<QUESTION
Для каждого из перечисленных ниже десятичных чисел построили
двоичную запись. Укажите число, двоичная запись которого содержит
ровно $type.
QUESTION
;
    $self->variants(@variants_ar);
    $self->{correct} = 0;
}
1;
