# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A01;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use Encode;

use EGE::Random;
use EGE::NumText;

sub bits_or_bytes { rnd->pick(bits_and_bytes($_[0])) }

sub _recode_get_encodings {
    my $change = shift;
    my $big = rnd->pick(
        { from => '16-битной кодировке UCS-2', to => '16-битную кодировку UCS-2' },
        { from => '2-байтном коде Unicode', to => '2-байтный код Unicode' }
    );
    my $little = rnd->pick(
      { from => '8-битной кодировке КОИ-8', to => '8-битную кодировке КОИ-8'},
    );
    { from => ($change ? $big : $little)->{from},
      to   => ($change ? $little : $big)->{to},
      change => $_[$change] }
}

sub recode {
    my ($self) = @_;
    my $delta = rnd->pick(8, 16, 32, map $_ * 10, 1..10);
    my $dir = _recode_get_encodings(rnd->coin(), 'увеличилось', 'уменьшилось');
    my $delta_text = bits_or_bytes($delta);
    $self->{text} = <<QUESTION
Автоматическое устройство осуществило перекодировку информационного сообщения,
первоначально записанного в $dir->{from}, в $dir->{to}.
При этом информационное сообщение $dir->{change} на $delta_text.
Какова длина сообщения в символах?
QUESTION
;
    $self->variants($delta * 8, $delta, int($delta / 2), $delta * 16);
    $self->{correct} = 1;
}

sub simple {
    my ($self) = @_;
    my $enc = rnd->pick(
        { name => 'UCS-2', size => 2 }, 
        { name => 'КОИ-8', size => 1 }, 
        { name => 'CP1251', size => 1 },
    );
    my @size_names = (
        [ '1 байтом', '8 битами' ],
        [ '2 байтами', '16 битами' ],
    );
    my $size_name = rnd->pick(@{$size_names[$enc->{size} - 1]});
    my $text = rnd->pick(
        'Известно, что Слоны в диковинку у нас.',
        'У сильного всегда бессильный виноват.',
        'Попрыгунья Стрекоза лето красное пропела',
    );
    $self->{text} = <<QUESTION
В кодировке $enc->{name} каждый символ кодируется $size_name. Определите объём
следующего предложения в данном представлении: <b>$text</b>.
QUESTION
;
    my $len = length $text;
    my $text_nosp = $text;
    $text_nosp =~ s/ //g;
    my $len_nosp = length $text_nosp;
    $self->variants(map bits_or_bytes($_), $len, 2 * $len, int($len / 8), $len_nosp);
    $self->{correct} = $enc->{size} - 1;
}

1;
