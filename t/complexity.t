use strict;
use warnings;
use utf8;

use Test::More tests => 42;
use Test::Exception;

use lib '..';
use EGE::Prog qw(make_block make_expr);

{
    my $e = make_expr([ '+', [ '*', 'x', [ '**', 'x', 2 ] ], [ '+', 'x', 2 ] ]);
    is $e->polinom_degree({ x => 1 }), 3, 'polinom degree';
    is make_expr('x')->polinom_degree({ x => 20 }), 20, 'polinom degree of var';
}

{
    my $e = make_expr([ '+', 'x', 'xyz' ]);
    throws_ok { $e->polinom_degree({ x => 1 }) } qr/Undefined variable xyz/, 'undefined var when calculating polinom degree';
}

{
    my $e = make_expr([ '**', 'x', 'y' ]);
    throws_ok { $e->polinom_degree({ x => 2, y => 3 }) } qr/Unknown variable y/, 'polinom degree of non-const power';
}

{
    throws_ok { make_expr([ '%', 'x', 'x' ])->polinom_degree({ x => 1 }) } qr/'%'/, 'polinom degree of expr with \'%\'';
    throws_ok { make_expr([ '!', 'x' ])->polinom_degree({}) } qr/'!'/, 'polinom degree of expr with \'!\'';
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ], []
    ]);
    is $b->complexity({ n => 1 }), 2, 'single forLoop complexity'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ], [
            'for', 'j', 0, 'n', []
        ]
    ]);
    is $b->complexity({ n => 1 }), 3, 'multi forLoop complexity'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ], [
            'for', 'j', 0, 'n' , [],
            'for', 'j', 0, [ '*', 'n', 'n' ], []
        ]
    ]);
    is $b->complexity({ n => 1 }), 4, 'block complexity'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
           'for', 'j', 0, 'i', []
        ]
    ]);
    is $b->complexity({ n => 1 }), 2, 'complexity with using var as border'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
            'for', 'j', 0, 'n', [
                'if', [ '!=', 'i', 'j' ], []
            ]
        ]
    ]);
    throws_ok { $b->complexity({ n => 1 }) } qr/!=/, 'IfThen complexity for condition with \'!=\''
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
            'if', [ '==', 'i', 'i' ], [
                'for', 'j', 0, 'n', []
            ]
        ]
    ]);
    is $b->complexity({ n => 1 }), 2, 'IfThen complexity for condition with same var'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ], [
            'for', 'j', 0, 'n', [
                'if', [ '==', 'i', 'j' ], [
                    'for', 'l', 0, 'n', []
                ]
            ],
            'for', 'k', 0, 'n', []
        ]
    ]);
    is $b->complexity({ n => 1 }), 3, 'IfThen complexity 1'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ] , [
            'for', 'j', 0, 'n', [
                'if', [ '==', 'i', 'j' ], [
                    'for', 'l', 0, 'n', []
                ]
            ],
            'for', 'k', 0, [ '*', 'i', 'j' ], [
                '=', [ '[]', 'M', 'i', 'j' ], [ '*', 'i', 'j' ]
            ]
        ]
    ]);
    is $b->complexity({ n => 1 }), 5, 'IfThen complexity 2'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ], [
            'for', 'j', 0, 'n', [
                'if', [ '==', 'i', 'j' ], [
                    'for', 'l', 0, [ '*', 'n', [ '*', 'i', 'j' ] ], [
                        'if', [ '==', 'i', 'l' ], []
                    ]
                ]
            ]
        ]
    ]);
    is $b->complexity({ n => 1 }), 4, 'multi IfThen complexity'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, ['*', [ '*', 'n', 'n' ], 'n'], [
            'if', [ '<=', 'i', 'n' ], [
                'for', 'j', 0, 'i', []
            ]
        ]
    ]);
    is $b->complexity({ n => 1 }), 3, 'IfThen complexity less condition'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ], [
            'for', 'j', 0, 'n', [
                'if', [ '==', 'i', 'j' ], [
                    'if', [ '<=', 'i', 10 ], [
                        'for', 'k', 0, ['*', ['*', 'i', 'n'], 'n'], []
                    ]
                ]
            ]
        ]
    ]);
    is $b->complexity({ n => 1} ), 3, 'IfThen complexity less and eq condition'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
            'if', [ '<=', 1, 'i' ], []
        ]
    ]);
    throws_ok { $b->complexity({ n => 1 }) } qr/EGE::Prog::Const/, 'IfThen complexity without var in less condition'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
            '=', 'i', 0
        ]
    ]);
    throws_ok { $b->complexity({ n => 1 }) } qr/i/, 'assign to iterator'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
            '=', 'j', [ '*', 'i', 'i' ]
        ]
    ]);
    throws_ok { $b->complexity({ n => 1 }) } qr/j/, 'assign iterator to another var'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
            'if', [ '==', 'i', 'n' ], [
                'for', 'j', 0, 'n', []
            ]
        ]
    ]);
    throws_ok { $b->complexity({ n => 1 }) } qr/a == b/, 'if_eq compare iterator with non-iterator'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '**', 'n', 2 ], [
            'for', 'j', 0, 'n', [
                'if', [ '==', [ '%', 'i', 'n' ], 0 ], [
                    'for', 'k', 0, [ '**', 'n', 3 ], []
                ],
                'for', 'l', 0, 1, []
            ]
        ]
    ]);
    is $b->complexity({ n => 1 }), 5, 'amortized analysis with if_mod';
    is $b->complexity({ n => 1 }, { ignore_if_mod => 1 }), 6, 'complexity with mistake ignore_if_mod';
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '**', 'n', 2 ], [
            'if', [ '==', [ '%', 'i', [ '**', 'n', 3 ] ], 0 ], [
                'for', 'j', 0, [ '**', 'n', 3 ], []
            ]
        ]
    ]);
    is $b->complexity({ n => 1 }), 3, 'complexity if_mod, divisor greater then dividend';
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ], [
            'for', 'j', 0, 'n', [
                'if', [ '==', 'i', 'j' ], [
                    'if', [ '<=', 'j', 10 ], [
                        'for', 'k', 0, [ '*', [ '*', 'i', 'i'], 'n' ], []
                    ]
                ]
            ],
            'for', 'l', 0, 'i', []
        ]
    ]);
    my @mistake_names = qw(var_as_const ignore_if_eq change_min ignore_if_less);
    my @ans = (4, 3, 7, 3, 3, 2, 4, 2, 4, 3, 8, 4, 4, 2, 4, 2);

    for (my $i = 1; $i < 2 ** @mistake_names; $i++) {
        my %mistakes = map(($mistake_names[$_] => $i / 2 ** $_ % 2), 0..$#mistake_names);
        $mistakes{var_as_const} and $mistakes{var_as_const} = 'n';
        is $b->complexity({ n => 1 }, \%mistakes), $ans[$i], 'complexity with mistakes: ' .
            join ', ', map($mistakes{$_} ? $_ : (), @mistake_names);
    }
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '**', 'n', 2 ], [
            'for', 'j', 0, [ '**', 'n', 3 ], [],
            'if', [ '==', 'i', 0 ], [
                'for', 'k', 0, [ '**', 'n', 4 ], []
            ]
        ]
    ]);
    is $b->complexity({ n => 1 }, { change_sum => 1 }), 9, 'complexity with change_sum';
    is $b->complexity({ n => 1 }, { change_sum => 1, 
                                    ignore_if_mod => 1 }), 11, 'complexity with change_sum + ignore_if_mod';    
    # change_min имеет больший приоритет чем change_sum
    is $b->complexity({ n => 1 }, { change_sum => 1,
                                    change_min => 1 }), 4, 'complexity with change_sum + change_min';
}
