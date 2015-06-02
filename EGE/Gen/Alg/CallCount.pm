# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::CallCount;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::LangTable;
use EGE::Prog;
use EGE::Random;

sub super_recursion {
    my ($self) = @_;
    my $n = 10 ** rnd->in_range(8, 12);
    my ($fst_part, $sec_part) = (int($n / rnd->in_range(20, 50)), int($n / rnd->in_range(20, 50) / 50));
    my ($div, $sub) = (rnd->in_range(2, 5), rnd->in_range(2, 5));
    my $code = [ 
        'func', [ 'f', 'n' ], [
            'if', [ '>=', 'n', $fst_part ], [
                '=', 'f', [ '+', [ '()', 'f', [ '/', 'n', $div] ], 1 ]
            ],
            'if', [ '&&', [ '<', 'n', $fst_part ], [ '>=', 'n', $sec_part ] ], [
                '=', 'f', ['+', [ '()', 'f', [ '-', 'n', $sub] ], 1 ]
            ], 
            'if', [ '<', 'n', $sec_part ], [
                '=', 'f', 1 
            ],
        ],
        'expr', [ 'print', [ '()', 'f', $n ] ],
    ];
    my $lt = EGE::LangTable::table(EGE::Prog::make_block($code), [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);

    my $div_count = 1;
    $div_count++ while ($n /= $div) >= $fst_part;
    $self->{correct} = $div_count + int(($n - $sec_part) / $sub) + 2;
    $self->{text} = "Определите количество вызовов функции <code>f</code> при исполнении следующего алгоритма:" .
    "<p><i>Прим.</i> Пренебречь размерностью целочисленных переменных.</p> $lt";
}

1;
