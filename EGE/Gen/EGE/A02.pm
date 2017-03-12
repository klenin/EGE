# Copyright © 2010-2013 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A02;
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
    my $char_cnt = rnd->in_range(2, 33);
    (my $base, my $base_name) = @{rnd->pick(
        [ 2, 'двоичные' ],
        [ 8, 'восьмеричные' ],
        [ 10, 'десятичные' ],
        [ 16, 'шестнадцатиричные' ],
    )};
    my $letters = num_text($char_cnt, [ 'различную букву', 'различные буквы', 'различных букв' ]);
    $c->{alph_text} = $c->{case_sensitive} ?
        "$base_name цифры и $letters " .
        'местного алфавита, причём все буквы используются в двух начертаниях: ' .
        'как строчные, так и заглавные (регистр буквы имеет значение!)'
    :
        "$letters и $base_name цифры";
    $c->{alph_length} = $char_cnt * ($c->{case_sensitive} ? 2 : 1) + $base;
}

sub _car_num_gen_task {
    my ($c) = @_;
    my $bits_per_item = ceil(log($c->{alph_length}) / log(2)) * $c->{sym_cnt};
    $c->{result} = [ map num_bytes($_ * $c->{items_cnt}),
        ceil($bits_per_item / 8),
        ceil($bits_per_item / 8 - 1),
        $bits_per_item,
        $c->{alph_length},
    ];
}

sub _car_num_gen_text {
    my ($c) = @_;
    my %number = (short => 'номер', forms => [ 'номерa', 'номеров', 'номеров' ]);
    my $obj_name = rnd->pick(
        { long => 'автомобильный номер', %number },
        { long => 'телефонный номер', %number },
        { long => 'почтовый индекс', short => 'индекс', forms => ['индекса', 'индексов', 'индексов'] },
        { long => 'почтовый адрес', short => 'адрес', forms => ['адреса', 'адресов', 'адресов'] },
        { long => 'номер медицинской страховки', %number }
    );
    my $items_cnt_text = num_text($c->{items_cnt}, $obj_name->{forms});
    my $sym_cnt_text = num_text($c->{sym_cnt}, [ 'символа', 'символов', 'символов' ]);
    <<QUESTION
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

    my $context = {
        case_sensitive => 0,
        sym_cnt => rnd->in_range(4, 20),
        items_cnt => rnd->in_range(2, 20),
    };
    _car_num_make_alphabet($context);
    _car_num_gen_task($context);

    $self->{text} = _car_num_gen_text($context);
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
        { bits => 5, q => qq~
Для передачи секретного сообщения используется код, состоящий из прописных букв 
русского языка (всего используются 32 различные буквы без пробелов). Каждая буква 
кода записывается при помощи минимально возможного количества бит. Определите 
информационный объём сообщения длиной в $n символов.~
        }
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
    my $small_unit_name = qw(байт бит)[$self->{correct} = rnd->coin];
    my $large_unit = rnd->pick(
        { name => 'Кбайт', power2 => 10, power10 => 3 },
        { name => 'Мбайт', power2 => 20, power10 => 6 },
        { name => 'Гбайт', power2 => 30, power10 => 9 },
    );
    $self->{text} = "Сколько $small_unit_name содержит $n $large_unit->{name}?";
    $self->variants(
        sprintf('2<sup>%d</sup>', $npower + $large_unit->{power2}),
        sprintf('2<sup>%d</sup>', $npower + $large_unit->{power2} + 3),
        sprintf('%d × 10<sup>%d</sup>', $n, $large_unit->{power10}),
        sprintf('%d × 10<sup>%d</sup>', 8 * $n, $large_unit->{power10}),
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
    my @edges = map { my $i = $_; map [ $_, $i ], 0 .. $n - 1; } 0 .. $n - 1;
    for my $e (rnd->pick_n($c->{edges_cnt}, @edges)) {
        my ($i, $j) = @$e;
        my $weight = rnd->in_range(@{$c->{weights_range}});
        $c->{routes}[$i][$j] = $c->{routes}[$j][$i] = $weight;
    }
    $c->{init_routes} = dclone($c->{routes});
}

sub push_uniq {
    my ($array, $value) = @_;
    push @$array, $value unless grep $_ == $value, @$array;
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
            push_uniq($ar->[$i][$j], $a, $b);
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
            next if $i == $j;
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
        push_uniq($c->{ans}, $_);
    }
    for my $k (0 .. $c->{n} - 1) {
        $_ = $c->{routes}[$k][$j];
        push_uniq($c->{ans}, $_) if defined $_;
    }

    while (@{$c->{ans}} < 4) {
        my $x = rnd->in_range($c->{weights_range}[0],
                              $c->{weights_range}[1]*$c->{towns_cnt});
        push_uniq($c->{ans}, $x);
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
                my $x = $c->{routes}[$v][$i];
                if (defined $x &&
                    (!defined $st[$i] || $st[$i] ne 'finished' && $d[$i] > $d[$v] + $x))
                {
                    $d[$i] = $d[$v] + $x;
                    $st[$i] = 'visited';
                }
            }
        }
    } while (@v);
    $d[$to]
}

sub _validate {
    my ($c) = @_;
    $c->{ans_from} != $c->{ans_to} or die "$c->{ans_from} == $c->{ans_to}";
    my $d = _dijkstra($c, $c->{ans_from}, $c->{ans_to}, 0);
    defined $d && $d == $c->{ans}[0] or die "$d != $c->{ans}[0]";
    @{$c->{ans}} >= 3 or die @{$c->{ans}};
    my %seen;
    $seen{$_}++ and die $_ for @{$c->{ans}};
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

sub sport_athlete {
    my ($self) = @_;
    my $athletes = rnd->pick(9..255);
    my $bits = ceil(log($athletes)/log(2));
    $self->{text} =
        "В соревновании участвуют $athletes атлетов. " .
        'Какое минимальное количество бит необходимо, чтобы кодировать номер каждого атлета?';
    $self->variants(
        num_bits($bits),
        rnd->pick_n(3,
            num_bits(int($bits * 1.5)),
            num_bits($bits + 1),
            num_bits($bits - 1)
        )
     );
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

