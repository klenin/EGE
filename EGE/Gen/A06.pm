package EGE::Gen::A06;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::LangTable;

sub count_by_sign {
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
    my $q =
        "Значения двух массивов A и B с индексами от 1 до $n " .
        "задаются при помощи следующего фрагмента программы: $lt" .
        "Какое количество элементов массива B[1..$n] будет принимать " .
        "$case->{name} значения после выполнения данной программы?";

    my $B = $b->run_val('B');
    my $c = grep $case->{test}->($B->[$_]), 1 .. $n;
    my @errors = ($c + 1, $c - 1, $n - $c, $n - $c + 1, $n - $c - 1);
    {
        question => $q,
        variants => [ $c, rnd->pick_n(3, @errors) ],
        answer => 0,
        variants_order => 'random',
    };
}

sub find_min_max {
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
    my $q =
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
    {
        question => $q,
        variants => [ map "B[$_]", $c, rnd->pick_n(3, @errors) ],
        answer => 0,
        variants_order => 'random',
    };
}

sub count_odd_even {
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
    my $q =
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
    my @errors = grep !$seen{$_}++,
        map $c + $_, -5 .. -1, 1 .. 5;
    {
        question => $q,
        variants => [ $c, rnd->pick_n(3, @errors) ],
        answer => 0,
        variants_order => 'random',
    };
}

sub alg_min_max {
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
    my $q =
        "Дан фрагмент программы, обрабатывающей массив A из N элементов: $lt" .
        'Чему будет равно значение переменной s после выполнения ' .
        'данного алгоритма, при любых значениях элементов массива A?';
    my $if_many = " из них, если $minmax->{text}ых элементов несколько)";
    my @v = (
        "\u$minmax->{text}ому элементу в массиве A",
        "Индексу $minmax->{text}ого элемента в массиве A (первому$if_many",
        "Индексу $minmax->{text}ого элемента в массиве A (последнему$if_many",
        "Количеству элементов, равных $minmax->{text}ому в массиве A"
    );
    {
        question => $q,
        variants => \@v,
        answer => $idx->{answer},
        variants_order => 'random',
    };
}

sub alg_avg {
    my ($i, $j) = rnd->pick_n(2, 'i', 'j', 'k', 'm'); # n занято размером массива

    my $pn = rnd->pick(
        { text => 'положительн', comp => '>' },
        { text => 'отрицательн', comp => '<' },
    );
    my $c = rnd->in_range(1, 3);
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
    my $q =
        'Дан фрагмент программы, обрабатывающей массив A из N элементов ' .
        "(известно, что в массиве имеются $pn->{text}ые элементы): $lt" .
        'Чему будет равно значение переменной s после выполнения ' .
        'данного алгоритма, при любых значениях элементов массива A?';
    my @v = (
        "Среднему арифметическому всех элементов массива A",
        "Среднему арифметическому всех $pn->{text}ых элементов массива A",
        "Количеству $pn->{text}ых элементов массива A",
        "Значению последнего $pn->{text}ого элемента массива A"
    );
    {
        question => $q,
        variants => \@v,
        answer => $c,
        variants_order => 'random',
    };
}

1;
