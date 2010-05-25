# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A15;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub color_name {
    my ($pure, @rgb) = @_;
    {
        '000' => 'Чёрный',
        '001' => 'Синий',
        '010' => 'Зелёный',
        '011' => 'Голубой',
        '100' => 'Красный',
        '101' => 'Фиолетовый',
        '110' => 'Желтый',
        '111' => ($pure ? 'Белый' : 'Серый')
    }->{join '', @rgb};
}

sub invert {
    my ($index, @rgb) = @_;
    map $rgb[$_] ^ ($_ == $index), 0 .. $#rgb;
}

sub rgb {
    my ($self) = @_;
    my @rgb = map rnd->coin, 1 .. 3;
    my $pure = rnd->coin;

    my $level = $pure ? 'FF' : sprintf '%X', rnd->in_range(200, 250);
    my $color = join '', map { $_ ? $level : '00' } @rgb;

    my $q = q~
Для кодирования цвета фона страницы Интернет используется атрибут
bgcolor="#XXXXXX", где в кавычках задаются шестнадцатеричные значения
интенсивности цветовых компонент в 24-битной RGB-модели.
Какой цвет будет у страницы, заданной тегом &lt;body bgcolor="%s">?
~;
    $self->{text} = sprintf($q, $color);
    $self->variants(map color_name($pure, invert $_, @rgb), -1 .. 2);
}

1;
