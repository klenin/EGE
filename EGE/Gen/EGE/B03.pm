# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B03;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NotationBase qw(dec_to_base base_to_dec);

sub q1234 {
    my ($self) = @_;
    my $base = rnd->pick(5, 6, 7, 9, 11);
    $self->{text} =
        "Какое десятичное число в системе счисления по основанию $base " .
        "записывается как 1234<sub>$base</sub>?";
    $self->{correct} = base_to_dec($base, 1234);
    $self->accept_number;
}

sub last_digit {
    my ($self) = @_;
    my $base = rnd->in_range(5, 9);
    my $last = rnd->in_range(0, $base - 1);
    my @corr = map $last + $base * $_, 0 .. 3;
    my $limit = $corr[-1] + rnd->in_range(0, $last - 1);

    $self->{text} =
        'Укажите в порядке возрастания через запятую без пробелов ' .
        'все неотрицательные десятичные числа, ' .
        "<b><u>не превосходящие</u></b> $limit, запись которых в системе " .
        "счисления с основанием $base оканчивается на $last.";
    $self->{correct} = join ',', @corr;
    $self->{accept} = qr/^(?:\d+,)+(\d+)$/;
}

sub count_digits {
    my ($self) = @_;
    my ($num, $base);
    do {
        $num = rnd->in_range(200, 900);
        $base = rnd->in_range(3, 9);
        $self->{correct} = length dec_to_base($base, $num);
    } until $self->{correct} > 3;
    $self->{text} =
        "Сколько значащих цифр в записи десятичного числа $num " .
        "в системе счисления с основанием $base?";
    $self->accept_number;
}

sub simple_equation {
    my ($self) = @_;
    my @dec_nums = map rnd->pick(20..200), 1..2;
    $dec_nums[2] = $dec_nums[0] + $dec_nums[1];
    my @bases = map rnd->pick(2..8), 1..3;
    my @nums = map dec_to_base($bases[$_], $dec_nums[$_]), 0..2;
    $self->{text} = 
        "Решите уравнение $nums[0]<sub>$bases[0]</sub> + <i>x</i> = $nums[2]<sub>$bases[2]</sub> " .
        "Ответ запишите в системе счисления с основанием $bases[1]";
    $self->{correct} = $nums[1];
    $self->accept_number;
}
1;
