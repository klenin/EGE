# Copyright © 2017 Vadim D. Kirpa
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::EGE::Z12;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NotationBase qw(base_to_dec dec_to_base);
use List::Util qw(min max);

sub computer_number {
    my ($self) = @_;
    my $un_num = rnd->in_range(3, 12);
    my $n = $un_num;
    my $octet1 = "1" x min(8, $un_num) . ("0" x max(8 - $un_num, 0));
    $un_num = max($un_num - 8, 0);
    my $octet2 = "1" x $un_num . ("0" x (8 - $un_num));
    my $dec1_m = base_to_dec(2, $octet1);
    my $dec2_m = base_to_dec(2, $octet2);
    my @dec_ip = map($_ == 0 ? rnd->in_range(128, 255) : rnd->in_range(0, 255), 0 .. 3);
    $self->{text} = 
        "Если маска подсети 255.255.$dec1_m.$dec2_m и IP-адрес компьютера в сети $dec_ip[0].$dec_ip[1].$dec_ip[2].$dec_ip[3], то номер компьютера в сети равен?";
    my $answer;
    for (2 .. 3) {
        $dec_ip[$_] = dec_to_base(2, $dec_ip[$_]);
        $dec_ip[$_] = "0" x (8 - length $dec_ip[$_]) . $dec_ip[$_];
        $answer .= substr($dec_ip[$_], $n, 8 - $n);
        $n = max($n - 8, 0);
    }
    $self->{correct} = base_to_dec(2, $answer);
    $self->accept_number;   
}

1;
