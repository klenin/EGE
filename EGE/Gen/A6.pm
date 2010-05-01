package EGE::Gen::A6;

use strict;
use warnings;

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
        '#', { 'C' =>
            '</pre>/* В программе на языке Си следует считать, что массивы A и B ' .
            'индексируются начиная с 1 и состоят из элементов ' .
            "A[1], &hellip; A[$n], " .
            "B[1], &hellip; B[$n] */<pre>"
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

sub max_or_min {
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
        "Значения двумерного массива A размера $n &times; $n " .
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

1;
