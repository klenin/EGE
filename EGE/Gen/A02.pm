# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A02;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NumText;

use POSIX qw(ceil);

sub sport {
    my ($self) = @_;
    my $flavour = rnd->pick(
        { t1 => 'велокроссе', t2 => [ 'велосипедист', 'велосипедиста', 'велосипедистов' ] },
        { t1 => 'забеге', t2 => [ 'бегун', 'бегуна', 'бегунов' ] },
        { t1 => 'марафоне', t2 => [ 'атлет', 'атлета', 'атлетов' ] },
        { t1 => 'заплыве', t2 => [ 'пловец', 'пловца', 'пловцов' ] },
    );
    my $bits = rnd->in_range(5, 7);
    my $total = 2 ** $bits - rnd->in_range(2, 5);
    my $passed = rnd->in_range($total / 2 - 5, $total / 2 + 5);
    my $passed_text = num_text($passed, $flavour->{t2});
    my $total_text = num_text($total, [ 'спортсмен', 'спортсмена', 'спортсменов' ]);
    $self->{text} = <<QUESTION
В $flavour->{t1} участвуют $total_text. Специальное устройство регистрирует
прохождение каждым из участников промежуточнго финиша, записывая его номер
с использованием минимального количества бит, одинакового для каждого спортсмена.
Каков информационный объем сообщения, записанного устройством,
после того как промежуточный финиш прошли $passed_text?
QUESTION
;
    $self->variants(
        num_bits($bits * $passed),
        rnd->pick_n(3,
            bits_and_bytes($total),
            bits_and_bytes($passed),
            num_bits($bits * $total)
        )
    );
}

sub make_alphabet {
    my $char_cnt = rnd->in_range(1, 33);
    my $base = rnd->pick(
        [2, 'двоичные'],
        [8, 'восьмеричные'],
        [10, 'десятичные'],
        [16, 'шеснадцатиричные']
    );
    my $text = num_text($char_cnt, ['букву', 'различные буквы', 'различных букв']);
    $text .= ' и ' . $base->[1] . ' цифры' if ($base->[0]);
    ($char_cnt + $base->[0], $text);
}

sub max_pow_contained {
    my ($n, $base) =  @_;
    return 1 if $n <= $base;
    my $pow = 0;
    --$n;
    while ($n) {
        $n = int($n / $base);
        ++$pow;
    }
    $pow;
}

sub car_numbers {
    my ($self) = @_;
    my $obj_name = rnd->pick(
        { long => 'автомобильный номер', short => 'номер',
               forms => ['номерa', 'номеров', 'номеров'] },
        { long => 'телефонный номер', short => 'номер',
               forms => ['номерa', 'номеров', 'номеров'] },
        { long => 'почтовый индекс', short => 'индекс',
               forms => ['индекса', 'индексов', 'индексов'] },
        { long => 'почтовый адрес', short => 'адрес',
               forms => ['адреса', 'адресов', 'адресов'] },
        { long => 'номер медецинской страховки', short => 'номер',
               forms => ['номерa', 'номеров', 'номеров'] }
    );
    my $sym_cnt = rnd->in_range(1, 20);
    my $items_cnt = rnd->in_range(1, 20);
    my $sym_cnt_text = num_text( $sym_cnt, ['символа', 'символов', 'символов'] );
    my ($alph_length, $alph_text) = make_alphabet();
    my $items_cnt_text = num_text( $items_cnt, $obj_name->{forms} );
    my $text = <<QUESTION
В некоторой стране $obj_name->{long} состоит из $sym_cnt_text. В качестве символов
используют $alph_text. Каждый такой $obj_name->{short} в компьютерной программе
записывается минимально возможным и одинаковым целым количеством байтов, при этом
используют посимвольное кодирование и все символы кодируются одинаковым и минимально
возможным количеством битов. Определите объем памяти, отводимый этой программой для
записи $items_cnt_text.
QUESTION
;
    my $bit_per_item = max_pow_contained($alph_length, 2) * $sym_cnt;
    my @ans = (
        ceil( $bit_per_item / 8 ) * $items_cnt,
        ceil( $bit_per_item / 8 - 1 ) * $items_cnt,
        $bit_per_item * $items_cnt,
        $alph_length * $items_cnt
    );
    $self->{text} = $text;
    $self->variants(map num_text($_, ['байт', 'байта', 'байт']), @ans);
}

sub bits_or_bytes { rnd->pick(bits_and_bytes($_[0])) }

sub database {
    my ($self) = @_;
    my $n = rnd->pick(map($_ * 10, 3..10), map($_ * 100, 2..9));
    # должно быть bits != 8
    my $flavour = rnd->pick(
        { bits => 7 * 4, q => qq~
В некоторой базе данных хранятся телефонные номера.
Каждый телефонный номер состоит из 7 десятичных цифр.
Каждая цифра кодируется отдельно с использованием минимального количества бит,
необходимых для записи одной цифры.
В базе данных записано $n телефонных номеров. Определите информационный объём базы.~
        },
        { bits => 7, q => qq~
Метеорологическая станция ведёт наблюдеине за влажностью воздуха.
Результатом одного наблюдения является целое число от 0 до 100%,
записываемое с использованием минимально возможного количества бит.
Станция сделала $n измерений. Определите информационный объём результатов наблюдений.~
        },
        { bits => 5, q => qq~
Для передачи секретного сообщения используется код, состоящий только из латинских букв
(всего используется 26 символов). При этом все символы кодируются
одним и тем же минимально возможным количеством бит.
Было передано закодированное сообщение, состоящее из $n символов.
Определите информационный объём переданного сообщения.~
        },
    );
    my $bits = $flavour->{bits} * $n;
    $self->{text} = $flavour->{q};
    $self->variants(
        rnd->pick(num_bits($bits), $bits % 8 ? () : num_bytes(int ($bits / 8))),
        bits_or_bytes($n),
        bits_or_bytes(2 * $n),
        num_bits($n),
    );
}

sub units {
    my ($self) = @_;
    my $npower = rnd->in_range(1, 4);
    my $n = 2 ** $npower;
    my $unit = rnd->pick(
        { name => 'Кбайт', power2 => 10, power10 => 3 },
        { name => 'Мбайт', power2 => 20, power10 => 6 },
        { name => 'Гбайт', power2 => 30, power10 => 9 },
    );

    $self->{text} = "Сколько бит содержит $n $unit->{name}?";
    $self->variants(
        sprintf('2<sup>%d</sup>', $npower + $unit->{power2}),
        sprintf('2<sup>%d</sup>', $npower + $unit->{power2} + 3),
        sprintf('%d × 10<sup>%d</sup>', $n, $unit->{power10}),
        sprintf('%d × 10<sup>%d</sup>', 8 * $n, $unit->{power10}),
    );
}

1;
