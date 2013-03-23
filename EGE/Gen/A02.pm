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
use EGE::Html;

use POSIX q(ceil);
use Storable q(dclone);
use List::Util q(reduce);

sub _assert { die ($_[1] // '')  unless $_[0] }

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

sub _car_num_make_alphabet {
    my ($c) = @_;
    my $char_cnt = rnd->in_range(1, 33);
    my $base = rnd->pick(
        [2, 'двоичные'],
        [8, 'восьмеричные'],
        [10, 'десятичные'],
        [16, 'шеснадцатиричные']
    );
    my $text = num_text($char_cnt, ['букву', 'различные буквы', 'различных букв']);
    if ($c->{case_sensetive}) {
        $text = $base->[1] . ' цифры и ' . $text .
            ' местного алфавита, причём все буквы используются в двух начертаниях' .
            ': как строчные, так и заглавные (регистр буквы имеет значение!)';
    } else {
        $text .= ' и ' . $base->[1] . ' цифры' if ($base->[0]);
    }
    @{$c}{qw(alph_length alph_text)} = ($char_cnt + $base->[0], $text);
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

sub _car_num_gen_params {
    my ($c) = @_;
    $c->{sym_cnt} = rnd->in_range(1, 20);
    $c->{items_cnt} = rnd->in_range(1, 20);
    _car_num_make_alphabet($c);
}

sub _car_num_gen_task {
    my ($c) = @_;
    my $bit_per_item = max_pow_contained($c->{alph_length}, 2) * $c->{sym_cnt};

    my @ans = (
        ceil( $bit_per_item / 8 ) * $c->{items_cnt},
        ceil( $bit_per_item / 8 - 1 ) * $c->{items_cnt},
        $bit_per_item * $c->{items_cnt},
        $c->{alph_length} * $c->{items_cnt}
    );
    $c->{result} = [map num_text($_, ['байт', 'байта', 'байт']), @ans]
}

sub _car_num_gen_text {
    my ($c) = @_;
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
    my $items_cnt_text = num_text( $c->{items_cnt}, $obj_name->{forms} );
    my $sym_cnt_text = num_text( $c->{sym_cnt}, ['символа', 'символов', 'символов'] );
    $c->{text} = <<QUESTION
В некоторой стране $obj_name->{long} состоит из $sym_cnt_text. В качестве символов
используют $c->{alph_text}. Каждый такой $obj_name->{short} в компьютерной программе
записывается минимально возможным и одинаковым целым количеством байтов, при этом
используют посимвольное кодирование и все символы кодируются одинаковым и минимально
возможным количеством битов. Определите объем памяти, отводимый этой программой для
записи $items_cnt_text.
QUESTION
}

sub car_numbers {
    my ($self) = @_;

    my $context = { case_sensetive => 0 };
    _car_num_gen_params($context);
    _car_num_gen_task($context);
    _car_num_gen_text($context);

    $self->{text} = $context->{text};
    $self->variants(@{$context->{result}});
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

sub _gen_params {
    my ($c) = @_;
    $c->{n} = $c->{towns_cnt} = 6;
    $c->{e} = $c->{edges_cnt} = rnd->in_range(5, 10);
    $c->{weights_range} = [1, 10];
}

sub _init_tables {
    my ($c) = @_;
    $c->{towns} = [ @{['A' .. 'Z']}[0 .. $c->{n} - 1] ];
    for my $i (0 .. $c->{n}- 1 ) {
        for my $j (0 .. $c->{n}- 1 ) {
            $c->{alt_routes}[$i][$j] = [];
            $c->{routes}[$i][$j] = undef;
        }
    }
}

sub _gen_init_routes {
    my ($c) = @_;
    _init_tables($c);

    my $n = $c->{towns_cnt};
    my @b = rnd->pick_n($c->{edges_cnt}, 0 .. $n*($n - 1)/2 );
    my $k = 0;
    for my $i (0 .. $c->{n} - 1) {
        for my $j ($i + 1 .. $c->{n} - 1) {
            if ($k ~~ @b) {
                my $weight = rnd->in_range(@{$c->{weights_range}});
                $c->{routes}[$i][$j] = $c->{routes}[$j][$i] = $weight;
            }
            ++$k;
        }
    }

    $c->{init_routes} = dclone($c->{routes});
}

sub _find_all_dists {
    my ($c) = @_;
    my $n = $c->{towns_cnt} - 1;
    my $r = $c->{routes};
    my $ar = $c->{alt_routes};
    my $relax = sub {
        my ($i, $j, $k) = @_;
        my ($a, $b, $c) = ($r->[$i][$k], $r->[$k][$j], $r->[$i][$j]);
        if (defined $a && defined $b) {
            $r->[$i][$j] = $a + $b if !defined $c || $c > $a + $b;
            push @{$ar->[$i][$j]}, $a + $b unless $a + $b ~~ @{$ar->[$i][$j]}
        }
    };
    for my $k (0 .. $n) {
        for my $i (0 .. $n) {
            for my $j (0 .. $n) {
                $relax->($i, $j, $k) if $i != $j
            }
        }
    }
}

sub _choose_from_to {
    my ($c) = @_;
    my ($first, $mi, $mj) = (1, 0, 0);
    for my $i (0 .. $c->{n} - 1) {
        for my $j (0 .. $c->{n} - 1) {
            if (($first  && defined $c->{routes}[$i][$j]) ||
                (!$first && @{$c->{alt_routes}[$i][$j]} > @{$c->{alt_routes}[$mi][$mj]}))
            {
                ($first, $mi, $mj) = (0, $i, $j)
            }
        }
    }
    @{$c}{qw(ans_from ans_to)} = ($mi, $mj);
}

sub _gen_task_and_answers {
    my ($c) = @_;
    _choose_from_to($c);
    my ($i, $j) = @{$c}{qw(ans_from ans_to)};
    $c->{ans} = [ $c->{routes}[$i][$j] ];
    for (@{$c->{alt_routes}[$i][$j]}) {
        push @{$c->{ans}}, $_ unless $_ ~~ $c->{ans};
    }
    for my $k (0 .. $c->{n} - 1) {
        $_ = $c->{routes}[$k][$j];
        push @{$c->{ans}}, $_ if defined $_ && !($_ ~~ $c->{ans});
    }

    while (@{$c->{ans}} < 4) {
        my $x = rnd->in_range($c->{weights_range}[0],
                              $c->{weights_range}[1]*$c->{towns_cnt});
        push @{$c->{ans}}, $x unless $x ~~ $c->{ans};
    }
}

sub _gen_text {
    my ($c) = @_;
    my $towns = join ', ', @{$c->{towns}};
    my $from  = $c->{towns}[$c->{ans_from}];
    my $to    = $c->{towns}[$c->{ans_to}];
    my $r =
        "Между населёнными пунктами $towns построены дороги, протяжённость " .
        'которых приведена в таблице. (Отсутствие числа в таблице означает, ' .
        'что прямой дороги между пунктами нет.) ';

    my $t = html->row_n('th', html->nbsp, @{$c->{towns}});
    for my $i (0 .. $#{$c->{init_routes}} ) {
        $t .= html->row_n('td', "<strong>$c->{towns}[$i]</strong>",
                          map { $_ // html->nbsp } @{$c->{init_routes}[$i] });
    }
    $r .= html->table($t, { border => 1 });
    $r .= "Определите длину кратчайшего пути между пунктами $from и $to " .
          '(при условии, что передвигаться можно только по построенным дорогам)';
    $c->{text} = $r;
}

sub _dijkstra {
    my ($c, $from, $to) = @_;
    my (@q, @st, @d);
    push @q, $from;
    $d[$from] = 0;
    $st[$from] = 'visited';
    my @v;
    do {
        @v = grep { defined $st[$_] && $st[$_] eq 'visited' } 0 .. $c->{n} - 1;
        if (@v) {
            my $v = reduce { defined $b ? ($d[$a] < $d[$b] ? $a : $b) : $a } @v;

            $st[$v] = 'finished';
            for my $i (0 .. $c->{n} - 1) {
                $_ = $c->{routes}[$v][$i];
                if (defined $_ &&
                    (!defined $st[$i] || $st[$i] ne 'finished' && $d[$i] > $d[$v] + $_))
                {
                    $d[$i] = $d[$v] + $_;
                    $st[$i] = 'visited';
                }
            }
        }
    } while (@v);
    $d[$to]
}

sub _validate {
    my ($c) = @_;
    $_ = _dijkstra($c, $c->{ans_from}, $c->{ans_to}, 0);
    _assert(defined $_ && $_ == $c->{ans}[0]);
    _assert(@{$c->{ans}} >= 3);
    for my $i (0 .. $#{$c->{ans}} - 1) {
        _assert(!($c->{ans}[$i] ~~ [@{$c->{ans}}[$i + 1 .. $#{$c->{ans}}]]))
    }
}

sub min_routes {
    my ($self) = @_;

    my $context = {};
    _gen_params($context);
    _gen_init_routes($context);
    _find_all_dists($context);
    _gen_task_and_answers($context);
    _gen_text($context);
    _validate($context);

    $self->{text} = $context->{text};
    $self->variants( @{$context->{ans}}[0 .. 3] );
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item sport

=item car_numbers

=item database

=item units

=item min_routes

=back


=head2 Генератор min_routes

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание A2.

=head3 Описание

=over

=item *

Выбираются количество городов и количество дорог.

=item *

Генерируется матрица смежности для неориентированного графа без петель (возможно)
с циклами.

=item *

Использоуется алгоритмом Флойда-Уоршолла для поиска расстояний между вершинами.
Причем во время работы алгоритма при улучшшении существующих значений в таблице
маршрутов запоминаются предыдущие значения(будут использованы в качестве
деструкторов).

=item *

Выбираются 2 вершины между которыми существует маршрут с наибольшим числом
деструкторов. В качестве недостающих вариантов ответов берутся длины маршрутов
из других вершин в конечную и случайные числа.

=back

