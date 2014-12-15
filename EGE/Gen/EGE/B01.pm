# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B01;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NumText;

use EGE::Gen::EGE::A01;

sub recode2 {
    my ($self) = @_;
    my $delta = rnd->pick(8, 16, 32, map $_ * 10, 1..10);
    my $dir =
        EGE::Gen::EGE::A01::_recode_get_encodings(rnd->coin(), 'увеличилась', 'уменьшилась');
    my $ans_in_bytes = rnd->coin();
    my $delta_text = $ans_in_bytes ? 'байт' : 'бит';
    $self->{text} =
        "Автоматическое устройство осуществило перекодировку информационного " .
        "сообщения на русском языке длиной в $delta символов, первоначально " .
        "записанного в $dir->{from}, в $dir->{to}. На сколько $delta_text " .
        "$dir->{change} длина сообщения? В ответе запишите только число.";
    $self->{correct} = $ans_in_bytes ? $delta : $delta*8;
    $self->accept_number;
}

sub direct {
    my ($self) = @_;
    my $sig_n = rnd->in_range(2, 5);
    my $sig_text = num_by_words($sig_n, 0, 'genitive');
    my $sec_n = rnd->in_range(2, 5);
    my $sec_text = EGE::NumText::num_by_words_text(
        $sec_n, 1, 'nomivative', [ qw(секунду секунды секунд) ]);
    $self->{text} =
        'Некоторое сигнальное устройство за одну секунду передает один из ' .
        "$sig_text сигналов. Сколько различных сообщений длиной в $sec_text " .
        'можно передать при помощи этого устройства?';
    $self->{correct} = $sig_n ** $sec_n;
    $self->accept_number;
}

1;
