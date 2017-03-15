# Copyright © 2017 Polina Vasilchenko
# Copyright © 2017 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::EGE::Z12;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub ip_computer_number {
    my ($self) = @_;
    my $subnet_bits = rnd->in_range(3, 12);
    my $comp_num = rnd->in_range(1, 2 ** $subnet_bits - 1);
    my $masked = (rnd->in_range(1, 2 ** (16 - $subnet_bits) - 1) << $subnet_bits) + $comp_num;
    my $mask = 2 ** 16 - 2 ** $subnet_bits;
    my $mask_text = ($mask >> 8) . '.' . ($mask & 255);
    $comp_num == ($masked & ~$mask) or die;

    my $dec_ip = join '.', rnd->in_range(128, 255), rnd->in_range(0, 255), $masked >> 8, $masked & 255;
    $self->{text} =
        "Если маска подсети 255.255.$mask_text и IP-адрес компьютера в сети $dec_ip, то номер компьютера в сети равен";
    $self->{correct} = $comp_num;
    $self->accept_number;
}

1;
