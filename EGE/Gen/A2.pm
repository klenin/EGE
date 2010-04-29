package EGE::Gen::A2;

use strict;
use warnings;

use EGE::Random;
use EGE::NumText;

sub sport {
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
    my $q = <<QUESTION
В $flavour->{t1} участвуют $total_text. Специальное устройство регистрирует
прохождение каждым из участников промежуточнго финиша, записывая его номер
с использованием минимального количества бит, одинакового для каждого спортсмена.
Каков информационный объем сообщения, записанного устройством,
после того как промежуточный финиш прошли $passed_text?
QUESTION
;
    {
        question => $q,
        variants => [
            num_bits($bits * $passed),
            rnd->pick_n(3,
                bits_and_bytes($total),
                bits_and_bytes($passed),
                num_bits($bits * $total)
            )
        ],
        answer => 0,
        variants_order => 'random',
    };
}

sub bits_or_bytes { rnd->pick(bits_and_bytes($_[0])) }

sub database {
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
Результатом одного наблюдения является целое число от 0 од 100%,
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
    {
        question => $flavour->{q},
        variants => [
            rnd->pick(num_bits($bits), $bits % 8 ? () : num_bytes(int ($bits / 8))),
            bits_or_bytes($n),
            bits_or_bytes(2 * $n),
            num_bits($n),
        ],
        answer => 0,
        variants_order => 'random',
    };
}

sub units {
    my $npower = rnd->in_range(1, 4);
    my $n = 2 ** $npower;
    my $unit = rnd->pick(
        { name => 'Кбайт', power2 => 10, power10 => 3 },
        { name => 'Мбайт', power2 => 20, power10 => 6 },
        { name => 'Гбайт', power2 => 30, power10 => 9 },
   );

    {
        question => "Сколько бит содержит $n $unit->{name}?",
        variants => [
            sprintf('2<sup>%d</sup>', $npower + $unit->{power2}),
            sprintf('2<sup>%d</sup>', $npower + $unit->{power2} + 3),
            sprintf('%d &times; 10<sup>%d</sup>', $n, $unit->{power10}),
            sprintf('%d &times; 10<sup>%d</sup>', 8 * $n, $unit->{power10}),
        ],
        answer => 0,
        variants_order => 'random',
    };
}

1;
