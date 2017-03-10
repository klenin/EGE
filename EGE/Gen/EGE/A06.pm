# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A06;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::LangTable;

sub count_by_sign {
    my ($self) = @_;
    my $n = rnd->in_range(50, 100);
    my $i = rnd->index_var;
    my $b = EGE::Prog::make_block([
        'for', $i, 1, $n, [
            '=', ['[]', 'A', $i], [ '*', $i, $i ],
        ],
        'for', $i, 1, $n, [
            '=', [ '[]', 'B', $i ], [ '-', [ '[]', 'A', $i ], $n ],
        ],
        '#', { 'C' => EGE::LangTable::unpre
            '/* В программе на языке Си следует считать, что массивы A и B ' .
            'индексируются начиная с 1 и состоят из элементов ' .
            "A[1], … A[$n], B[1], … B[$n] */"
        }
    ]);
    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C' ] ]);
    my $case = rnd->pick(
        { name => 'положительные', test => sub { $_[0] > 0 } },
        { name => 'отрицательные', test => sub { $_[0] < 0 } },
        { name => 'неотрицательные', test => sub { $_[0] >= 0 } },
    );
    $self->{text} =
        "Значения двух массивов A и B с индексами от 1 до $n " .
        "задаются при помощи следующего фрагмента программы: $lt" .
        "Какое количество элементов массива B[1..$n] будет принимать " .
        "$case->{name} значения после выполнения данной программы?";

    my $B = $b->run_val('B');
    my $c = grep $case->{test}->($B->[$_]), 1 .. $n;
    my @errors = ($c + 1, $c - 1, $n - $c, $n - $c + 1, $n - $c - 1);
    $self->variants($c, rnd->pick_n(3, @errors));
}

sub find_min_max {
    my ($self) = @_;
    my $n = rnd->in_range(50, 100);
    # нужно гарантировать единственные максимум и минимум
    my $m = rnd->in_range($n / 2 + 1, $n - 1);
    my $i = rnd->index_var;
    my $d1 = [ '-', rnd->shuffle($i, $m) ];
    my ($d2, $d3) = rnd->shuffle($i, [ '-', $n + 1, $i ]);
    my $b = EGE::Prog::make_block([
        'for', $i, 1, $n, [
            '=', [ '[]', 'A', $i ], [ '*', $d1, $d1 ]
        ],
        'for', $i, 1, $n, [
            '=', [ '[]', 'B', $d2 ], [ '[]', 'A', $d3 ],
        ],
    ]);
    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Pascal', 'Alg' ] ]);
    my $case = rnd->pick(
        { name => 'наибольшим', test => 1 },
        { name => 'наименьшим', test => -1 },
    );
    $self->{text} =
        "Значения двух массивов A[1..$n] и B[1..$n] " .
        "задаются с помощью следующего фрагмента программы: $lt" .
        "Какой элемент массива B будет $case->{name}?";

    my $B = $b->run_val('B');
    my ($c, $w) = (1, 1);
    for (2 .. $n) {
        $c = $_ if ($B->[$_] <=> $B->[$c]) * $case->{test} > 0;
        $w = $_ if ($B->[$_] <=> $B->[$c]) * $case->{test} < 0;
    }
    my %seen = ($c => 1);
    my @errors = grep 1 <= $_ && $_ <= $n && !$seen{$_}++,
        ($c + 1, $c - 1, $n - $c, $n - $c + 1, $n - $c - 1, $w, $n - $w );
    $self->variants(map "B[$_]", $c, rnd->pick_n(3, @errors));
}

sub count_odd_even {
    my ($self) = @_;
    my $n = rnd->in_range(7, 10);
    my ($i, $j) = rnd->index_var(2);
    my $b = EGE::Prog::make_block([
        'for', $i, 1, $n, [
            'for', $j, 1, $n, [
                '=',
                    [ '[]', 'A', $i, $j ],
                    [ '+', $i, [ rnd->pick('+', '-'), $j, 1 ] ]
            ],
        ],
    ]);
    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Pascal', 'Alg' ] ]);
    my $case = rnd->pick(
        { name => 'чётное', test => 0 },
        { name => 'нечётное', test => 1 },
    );
    $self->{text} =
        "Значения двумерного массива A размера $n × $n " .
        'задаются с помощью вложенного оператора цикла ' .
        "в представленном фрагменте программы: $lt" .
        "Сколько элементов массива A будут принимать $case->{name} значение?";

    my $A = $b->run_val('A');
    my $c = 0;
    for my $ii (1 .. $n) {
        for my $jj (1 .. $n) {
            ++$c if  $A->[$ii][$jj] % 2 == $case->{test}
        }
    }
    my %seen = ($c => 1);
    my @errors = grep !$seen{$_}++, map $c + $_, -5 .. -1, 1 .. 5;
    $self->variants($c, rnd->pick_n(3, @errors));
}

sub alg_min_max {
    my ($self) = @_;
    my ($i, $j) = rnd->pick_n(2, 'i', 'j', 'k', 'm'); # n занято размером массива

    my $minmax = rnd->pick(
        { text => 'максимальн', comp => '>' },
        { text => 'минимальн', comp => '<' },
    );
    my $eq = rnd->pick(
        { answer => 1, comp => '' },
        { answer => 2, comp => '=' },
    );
    my $idx = rnd->pick(
        { answer => 0, res => [ '[]', 'A', $j ] },
        { answer => $eq->{answer}, res => $j },
    );
    my $b = EGE::Prog::make_block([
        '=', $j, 1,
        'for', $i, 1, 'N', [
            'if', [ "$minmax->{comp}$eq->{comp}", [ '[]', 'A', $i ], [ '[]', 'A', $j ] ],
                [ '=', $j, $i ],
        ],
        '=', 's', $idx->{res},
    ]);
    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Pascal', 'Alg' ] ]);
    $self->{text} =
        "Дан фрагмент программы, обрабатывающей массив A из N элементов: $lt" .
        'Чему будет равно значение переменной s после выполнения ' .
        'данного алгоритма, при любых значениях элементов массива A?';
    my $if_many = " из них, если $minmax->{text}ых элементов несколько)";
    $self->variants(
        "\u$minmax->{text}ому элементу в массиве A",
        "Индексу $minmax->{text}ого элемента в массиве A (первому$if_many",
        "Индексу $minmax->{text}ого элемента в массиве A (последнему$if_many",
        "Количеству элементов, равных $minmax->{text}ому в массиве A"
    );
    $self->{correct} = $idx->{answer};
}

sub alg_avg {
    my ($self) = @_;
    my ($i, $j) = rnd->pick_n(2, 'i', 'j', 'k', 'm'); # n занято размером массива

    my $pn = rnd->pick(
        { text => 'положительн', comp => '>' },
        { text => 'отрицательн', comp => '<' },
    );
    my $c = $self->{correct} = rnd->in_range(1, 3);
    my $Ai = [ '[]', 'A', $i ];
    my $b = EGE::Prog::make_block([
        '=', 's', 0,
        '=', $j, 1,
        'for', $i, 1, 'N', [
            'if', [ $pn->{comp}, $Ai, 0 ], [
                '=', 's', ($c == 3 ? $Ai : [ '+', 's', $Ai ]),
                '=', $j, [ '+', $j, 1 ],
            ],
        ],
        ($c == 3 ? () : ('=', 's', $c == 1 ? [ '/', 's', $j ] : $j)),
    ]);
    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Pascal' ], [ 'C', 'Alg' ] ]);
    $self->{text} =
        'Дан фрагмент программы, обрабатывающей массив A из N элементов ' .
        "(известно, что в массиве имеются $pn->{text}ые элементы): $lt" .
        'Чему будет равно значение переменной s после выполнения ' .
        'данного алгоритма, при любых значениях элементов массива A?';
    $self->variants(
        "Среднему арифметическому всех элементов массива A",
        "Среднему арифметическому всех $pn->{text}ых элементов массива A",
        "Количеству $pn->{text}ых элементов массива A",
        "Значению последнего $pn->{text}ого элемента массива A",
    );
}

sub stime { return int($_[0] / 60 + 7) . ":" . sprintf("%02d", $_[0] % 60) }

sub random_routes {
# Генерация случайных маршрутов без петель
# |~|1|2|3| каждому целому числу от 0 до $n * ($n - 1) можно
# |4|~|5|6| однозначно сопоставить позицию в матрице смежности
# |7|8|~|9|
# ...
    my ($path_count, $n) = @_;
    my @b = rnd->pick_n($path_count, 0 .. $n*($n - 1) - 1);
    my @v;
    for (@b) {
        my ($x, $y) = ($_ % ($n - 1), int($_ / ($n - 1)));
        ++$x if $x >= $y;
        push @v, { from => $x, to => $y };
    }
    my $time = 0;
    for (@v) {
        $time += 5 * rnd->in_range(2, 20);
        $_->{start} = $time;
        $_->{fin} = $time + 5 * rnd->in_range(1, 10);
    }
    @v;
}

sub find_all_routes {
# Для нахождения кратчайших расстояний используется Алгоритм Флойда — Уоршелла
    my ($a, $n) = @_;
    for my $k (0 .. $n) {
        for my $i (0 .. $n) {
            for my $j (0 .. $n) {
                my ($v, $u, $w) = ($a->[$i][$j], $a->[$i][$k], $a->[$k][$j]);
                next if !defined $u->{fin} || !defined $w->{start} || ($u->{fin} > $w->{start});
                if (!defined $v->{start} || ($v->{fin} > $w->{fin})) {
                    $v->{pred_res} = $v->{fin} if defined $v->{fin};
                    $v->{fin} = $w->{fin};
                    $v->{start} = $u->{start};
                    $v->{from} = $u->{from};
                    $v->{to} = $w->{to};
                }
            }
        }
    }
}

sub gen_schedule_text {
    my ($way, $towns, $v) = @_;
    my $start_time = stime(5 * rnd->in_range(0, int($way->{start}/5)));
    my $text = <<TEXT
<p>
Путешественник пришел в $start_time на автостанцию населенного пункта
<strong>$towns->[$way->{from}]</strong> и обнаружил следующее расписание автобусов для всей районной
сети маршрутов:
</p>
<table border="1">
<tr>
<th>Пункт отправления</th>
<th>Пункт прибытия</th>
<th>Время отправления</th>
<th>Время прибытия</th>
</tr>
TEXT
;
    for (@{$v}) {
        $text .= "<tr>";
        $text .= "<td>$towns->[$_->{from}]</td>";
        $text .= "<td>$towns->[$_->{to}]</td>";
        $text .= "<td>" . stime($_->{start}) . "</td>";
        $text .= "<td>" . stime($_->{fin}) . "</td>";
        $text .= "</tr>\n";
    }
    $text .= "</table>\n";
    $text .= "<p>Определите самое раннее время, когда путешественник сможет оказаться в
пункте <strong>$towns->[$way->{to}]</strong> согласно этому расписанию.</p>";
    $text;
}

sub bus_station {
    my ($self) = @_;
    my $towns_count = 4;
    my @towns = rnd->pick_n($towns_count, qw(ЛИСЬЕ СОБОЛЕВО ЕЖОВО ЗАЙЦЕВО МЕДВЕЖЬЕ ПЧЕЛИННОЕ));
    my @init_verts = random_routes(rnd->in_range(6, 10), $towns_count);
    my $a = [];
    $a->[$_->{from}][$_->{to}] = $_ for @init_verts;
    find_all_routes($a, $towns_count);
    my @can_go;
    for (@{$a}) {
        for (@{$_}) {
            push(@can_go, $_) if (defined $_->{fin});
        }
    }
    my $way = rnd->pick(@can_go);
    # Добавляется верный ответ. Затем, если такой существует, предыдущий, затёртый алгоритмом
    # нахождения кратчайших путей вариант. Далее выбираются маршруты, которые ведут в пункт назначения.
    # Если не набралось 4 варианта выбираются случайные ответы.
    # При добавлении проверяется уникальность ответов.
    my @ans = ($way->{fin});
    push (@ans, $way->{pred_res}) if defined $way->{last_time};
    for my $i (@ans .. $towns_count - 1) {
        my $elem = $a->[$i][$way->{to}];
        if (defined $elem->{fin}) {
            push (@ans, $elem->{fin}) unless grep $_ == $elem->{fin}, @ans;
        }
    }
    for (@ans .. $towns_count - 1) {
        my $elem;
        do { $elem = rnd->pick(@can_go) } while grep $_ == $elem->{fin}, @ans;
        push (@ans, $elem->{fin});
    }
    $self->{text} = gen_schedule_text($way, \@towns, \@init_verts);
    $self->variants(map stime($_), @ans);
}

sub check_match {
   my @check_el = @_;
   return ($check_el[1] eq $check_el[0]) || ($check_el[2] eq $check_el[0]) || ($check_el[3] eq $check_el[0]);
}

sub wr_ans {
    my @used = @_;
    my @wrong_ans;
    my $n_null = 0;
    my @str = split(/ /, $used[0], -1);
    my @copy;
    foreach (0..2){
        my $get = 0;
        while ($n_null < 3){
            $n_null += 1;
            if ($str[$n_null - 1] ne '0000000'){
                @copy = @str;
                $copy[$n_null - 1] = '0000000';
                if (check_match("@copy", $used[0], $used[1], $used[2])){
                    next;
                }
                $wrong_ans[$_] = "@copy";
                $get = 1;
                last;
            }
        }
        if ($get){ next; }
        @copy = @str;
        do {
            substr($copy[int(rand(3))], int(rand(7)), 1) = int(rand(2));
        } while (check_match("@copy", $used[0], $used[1], $used[2]));
        $wrong_ans[$_] = "@copy";
    }
    return $wrong_ans[0], $wrong_ans[1], $wrong_ans[2];
}

sub par_check {
    my $str = "@_";
    my $n = 0;
    foreach (0..((length $str) - 1)){
        $n += int(substr($str, $_, 1));
    }
    return $n % 2;
} 

sub bad_message {
    my ($self) = @_;
    my @text1; 
    foreach my $i (0..2){
        $text1[$i] = '';
        foreach my $j (0..5){
            $text1[$i] .= rnd->in_range(0, 1);
        }
        $text1[$i] .=  par_check($text1[$i]);
        
    }
    my @text2 = @text1;
    foreach my $i (0..2){
        foreach my $j (0..6){
            if (rnd->in_range(0, 1)){
                substr($text2[$i], $j, 1) = (substr($text2[$i], $j, 1) + 1) % 2;
            }
        }
    }
    my @answer = @text2; 
    foreach (0..2){
        if (par_check($answer[$_])){
            $answer[$_] = '0000000';
        }
    }
    $self->{text} = <<QUESTION
В некоторой информационной системе информация кодируется двоичными шестиразрядными словами. 
При передаче данных возможны их искажения, поэтому в конец каждого слова добавляется седьмой 
(контрольный) разряд таким образом, чтобы сумма разрядов нового слова, считая контрольный, 
была чётной. Например, к слову 110011 справа будет добавлен 0, а к слову 101100 – 1.
После приёма слова производится его обработка. При этом проверяется сумма его разрядов,
включая контрольный. Если она нечётна, это означает, что при передаче этого слова произошёл сбой, 
и оно автоматически заменяется на зарезервированное слово 0000000. Если она чётна, это означает,
что сбоя не было или сбоев было больше одного. В этом случае принятое слово не изменяется.
Исходное сообщение : <b>@text1</b> было принято в виде : <b>@text2</b>.
Как будет выглядеть принятое сообщение после обработки?
QUESTION
;
    
    my @m = ("@answer", "@text2", "@text1");
    $self->variants("@answer", wr_ans(@m));
}

sub convert_number {
    my ($self) = @_;
    my $num = rnd->in_range(111, 998);
    my $answer = $num;
    my @digit = split(//, $num);
    my $getmin = 0;
    if ($digit[0] > $digit[2]){   
        ($digit[0], $digit[2]) = ($digit[2], $digit[0]);
        $getmin = 1;
        
    }
    my $res_number = ($digit[0] + $digit[1]) . ($digit[1] + $digit[2]);
    $self->{text} = <<QUESTION
Автомат получает на вход трёхзначное число. По этому числу строится новое число по следующим правилам.<br />
1. Складываются первая и вторая, а также вторая и третья цифры исходного числа.<br />
2. Полученные два числа записываются друг за другом в порядке возрастания (без разделителей).<br />

Пример. Исходное число: 348. Суммы: 3+4 = 7; 4+8 = 12. Результат: 712.<br />
Укажите наименьшее число, в результате обработки которого автомат выдаст число $res_number.
QUESTION
;
    $self->variants($digit[0] . $digit[1] . $digit[2], $getmin ? $num : ($num + 1), $digit[0] . (($digit[1] + 2) % 10) . $digit[2], $digit[0] . (($digit[1] + 1) % 10) . $digit[2]);
}

sub inf_size {
    my ($self) = @_;
    my $pow = rnd->in_range(4, 15);
    my $v = 2**$pow;
    my $time = rnd->in_range(4, 19);
    $self->{text} = <<QUESTION
Известно, что длительность непрерывного подключения к сети Интернет с помощью модема для некоторых АТС не превышает $time минут.
Определите максимальный размер файла (в Килобайтах), который может быть передан за время такого подключения,
если модем передает информацию в среднем со скоростью $v Килобит/с?
QUESTION
;
    $time *= 60;
    $self->variants((2**($pow - 3)) * $time, (2**$pow) * $time, ((2**($pow - 3)) * $time)/60, (2**($pow + 7)) * $time);
}

sub get_bin {
    my $num = $_[0];
    my $bin = '';
    while ($num){
        $bin = ($num % 2) . $bin;
        $num = int($num / 2);
    }
    return $bin;
}
    
sub bin_number {
    my ($self) = @_;
    my $n = rnd->in_range(50, 249);
    $self->{text} = <<QUESTION
На вход алгоритма подаётся натуральное число N. Алгоритм строит по нему новое число R следующим образом.<br />
1. Строится двоичная запись числа N.<br />
2. К этой записи дописываются справа ещё два разряда по следующему правилу:<br />
а) складываются все цифры двоичной записи, и остаток от деления суммы на 2 дописывается в конец числа (справа). Например, запись 11100 преобразуется в запись 111001;<br />
б) над этой записью производятся те же действия – справа дописывается остаток от деления суммы цифр на 2.<br />
<br />
Полученная таким образом запись (в ней на два разряда больше, чем в записи исходного числа N) является двоичной записью искомого числа R.
Укажите такое наименьшее число N, для которого результат работы алгоритма больше $n.
QUESTION
;   
    my $par = 0;
    my @bin_n;
    while(1) {
        $n += 1;
        @bin_n = split(//, get_bin($n));
        $par = 0;
        for (my $i = 0; $i < @bin_n - 2; $i++){
            $par += $bin_n[$i];
        }
        if (($par % 2) == $bin_n[@bin_n - 2] && $bin_n[@bin_n - 1] == 0){
            last;
        }            
    }
    my $answer = ($n - 2*$bin_n[@bin_n - 2])/ 4;
    $self->variants($answer, $answer + 4, $n, $n - 1); 
}

1;
