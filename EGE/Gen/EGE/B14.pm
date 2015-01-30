# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B14;
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
    my $beg = rnd->in_range(-$bord-10, -$bord);
    my $end = rnd->in_range($bord, $bord + 10);
    my $x1 = rnd->in_range(-$bord, -$bord + 10);
    my $x2 = rnd->in_range($bord-10, $bord);
    my $param = rnd->index_var;
    my $b = EGE::Prog::make_block([
        'func', 'F', [ $param ], [
            '=', 'F', [
                '*', 
                    [ '+', $param, -$x1 ], 
                    [ '-', $param, $x2 ]
                ]
        ],
        
        '=', 'A', $beg,
        '=', 'B', $end,        
        '=', 'M', 'A',
        '=', 'R', [ '()', 'F', 'A' ],
        
        'for', 'i', 'A', 'B', [
            'if', [ '<', [ '()', 'F', 'i' ], 'R' ], [
                '=', 'M', 'i',
                '=', 'R', [ '()', 'F', 'i' ] 
            ]
        ]
    ]);

    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C' ] ]);
    $self->{text} = "Определите значение переменной M после выполнения следующего алгоритма: $lt";
    $self->{correct} = $b->run_val('M');
    $self->{accept} = qr/^-?\d+$/;
}

1;
