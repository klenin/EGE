# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B14;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::LangTable;

sub find_func_min {
    my ($self) = @_;
    my $bord = 20;
    my ($beg, $end) = (rnd->in_range(-$bord-10, -$bord), rnd->in_range($bord, $bord+10));
    my ($x1, $x2) = (rnd->in_range(-$bord, -$bord+10), rnd->in_range($bord-10, $bord));
    my ($i, $inner_var) = ('i', rnd->index_var);
    my $b = EGE::Prog::make_block([
        'func', 'F', [$inner_var], [
            '=', 'F', 
                ['*', 
                    ['+', $inner_var, -$x1], 
                    ['-', $inner_var, $x2]
                ]
        ],
        
        '=', 'A', $beg,
        '=', 'B', $end,        
        '=', 'M', 'A',
        '=', 'R', ['()', 'F', ['A']],
        
        'for', $i, 'A', 'B', [
            'if',  ['<', ['()', 'F', [$i]], 'R'], [
                '=', 'M', $i,
                '=', 'R', ['()', 'F', [$i]] 
            ]
        ]
    ]);

    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C', 'Perl' ] ]);
    $self->{text} = "Определите значение переменной M выполнения следующего алгоритма: $lt";
    $self->{correct} = $b->run_val('M');
    #$self->accept_number;
}

1;