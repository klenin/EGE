use strict;
use warnings;
use utf8;

use Test::More tests => 133;
use Test::Exception;

use lib '..';
use EGE::Prog qw(make_block make_expr);

{
    my @t = (
        [ '+', 4, 5 ],    9,
        [ '*', 4, 5 ],   20,
        [ '/', 4, 5 ],  0.8,
        [ '%', 14, 5 ],   4,
        [ '//', 14, 5 ],  2,
        [ '<', 4, 5 ],    1,
        [ '&&', 1, 0 ],   0,
        [ '||', 1, 0 ],   1,
        [ '-', 4 ],      -4,
        [ '!', 0 ],       1,
        [ '**', 2, 8 ], 256,
        55,              55,
        sub { 77 },      77,
    );
    my $i = 0;
    is make_expr(shift @t)->run({}), shift @t, 'op ' . ++$i while @t;
    my $env = { a => 2, b => 3 };
    is make_expr('b')->run($env), 3, 'basic env 1';
    is make_expr([ '*', 'a', [ '+', 'b', 7 ] ])->run($env), 20, 'basic env 2';
}

{
    is make_expr(sub { $_[0]->{z} * 2 })->run({ z => 9 }), 18, 'black box';
    my $bb = EGE::Prog::BlackBox->new(lang => { 'C' => 'test' });
    is $bb->to_lang(EGE::Prog::Lang::lang('C')), 'test', 'black box text';
    my $h = { y => 5 };
    make_expr(sub { $_[0]->{y} = 6 })->run($h);
    is $h->{y}, 6, 'black box assign';
}

{
    my $e = make_expr([ '!', [ '>', 'A', 'B' ] ]);
    is $e->to_lang_named('Basic'), 'NOT (A > B)', 'not()';
    is $e->to_lang_named('Logic'), '¬ (<i>A</i> > <i>B</i>)', 'not in logic';
    ok make_expr([ '||', [ '!', [ '&&', 1, 1 ] ], 1 ]), 'all logic';
}

{
    my $e = make_expr([ 'between', 'a', '1', [ '+', '2', '5' ] ]);
    is $e->run({ a => 3 }), 1, 'between 1';
    is $e->run({ a => 8 }), 0, 'between 2';
    is $e->to_lang_named('C'), '1 <= a && a <= 2 + 5', 'between C';
    is $e->to_lang_named('Pascal'), 'InRange(a, 1, 2 + 5)', 'between Pascal';
    is $e->to_lang_named('SQL'), 'a BETWEEN 1 AND 2 + 5', 'between SQL';
}

{
    my $e = make_expr([ '+', 'a', 3 ]);
    is_deeply make_expr($e), $e, 'double make_expr';
}

{
    my $env = { a_1 => 2, a_b => 3 };
    is make_expr('a_b')->run($env), 3, 'var underline';
    is make_expr('a_1')->run($env), 2, 'var digit';
    throws_ok { make_expr(['xyz'])->run({}) } qr/xyz/, 'undefined variable';
}

{
    sub plus2minus { $_[0]->{op} = '+' if ($_[0]->{op} || '') eq '-' }
    my $e = make_expr([ '-', [ '-', 3, ['-', 2, 1 ] ] ]);
    is $e->run(), -2, 'visit_dfs before';
    is $e->visit_dfs(\&plus2minus)->run(), 6, 'visit_dfs after';
    is $e->count_if(sub { 1 }), 6, 'visit_dfs count all';
    is $e->count_if(sub { $_[0]->isa('EGE::Prog::Const') }), 3, 'count_if';
}

{
    my $e = make_expr([ '[]', 'A', map [ '+', 'i', $_ ], 1 .. 5 ]);
    $e->visit_dfs(sub { $_[0] = $_[0]->{right} if $_[0]->isa('EGE::Prog::BinOp') });
    is $e->to_lang_named('Pascal'), 'A[1, 2, 3, 4, 5]', 'visit transform';
    $e->visit_dfs(sub { $_[0] = make_expr 11 });
    is $e->run(), 11, 'visit transform all';
}

sub check_lang {
    my ($lang, $expr, $str, $name) = @_;
    is make_expr($expr)->to_lang_named($lang), $str, $name;
}

sub check_prio_C { check_lang 'C', @_[0..1], "priorities $_[2]" }

{
    check_prio_C [ '*', [ '+', 'a', 1 ], [ '-', 'b', 2 ] ], '(a + 1) * (b - 2)', '1';
    check_prio_C [ '+', [ '*', 'a', 1 ], [ '/', 'b', 2 ] ], 'a * 1 + b / 2', '2';
    check_prio_C [ '*', 5, [ '-', 'x' ] ], '5 * - x', 'unary 1';
    check_prio_C [ '+', 5, [ '-', 'x' ] ], '5 + - x', 'unary 2';
    check_prio_C [ '-', [ '+', 'x', 5 ] ], '- (x + 5)', 'unary 3';
    check_prio_C [ '+', [ '-', 'x' ] ], '+ - x', 'unary 4';

    my $e = [ '+', [ '&&', 'x', 'y' ] ];
    check_lang 'Pascal', $e, '+ (x and y)', 'prio Pascal not';
    check_prio_C $e, '+ (x && y)', 'C not';
}

{
    check_lang 'Pascal', [ '+', 'x', [ '**', 'x', 2 ] ], 'x + x ** 2', 'Pascal power' 
}

{
    my $e = make_expr([ '&&', [ '<=', 1, 'a' ], [ '<=', 'a', 'n' ] ]);
    is $e->to_lang_named('C'), '1 <= a && a <= n', 'logic priorities C';
    is $e->to_lang_named('Pascal'), '(1 <= a) and (a <= n)', 'logic priorities Pascal';
}

{
    my $b = make_block([]);
    is $b->to_lang_named($_), '', $_ for keys %{EGE::Prog::lang_names()};
    throws_ok { make_block(['xyz']) } qr/xyz/, 'undefined statement';
}

{
    my $b = make_block([ '=', 'x', 99 ]);
    is $b->to_lang_named('Alg'), 'x := 99';
    is $b->run_val('x'), 99;
}

{
    my $b = make_block([ '=', 'x', 3, '=', 'y', 'x' ]);
    is $b->to_lang_named('Perl'), "\$x = 3;\n\$y = \$x;";
    is $b->run_val('y'), 3;
}

{
    my $m = 5;
    my $b = make_block([ '=', 'x', ['+', \$m, 1 ] ]);
    is $b->run_val('x'), 6;
    $m = 10;
    is $b->run_val('x'), 11;
}

{
    my $b = make_block([ '#', { 'Basic' => 'basic text' }]);
    is $b->to_lang_named('Basic'), 'basic text';
    is $b->to_lang_named('C'), '';
}

{
    my $b = EGE::Prog::make_block([ '=', [ '[]', 'A', 2 ], 5 ]);
    is $b->to_lang_named('Pascal'), 'A[2] := 5;';
    is_deeply $b->run_val('A'), [ undef, undef, 5 ];
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 4, [ '=', ['[]', 'M', 'i'], 'i' ]
    ]);
    my $p = q~for i := 0 to 4 do
  M[i] := i;~;
    is $b->to_lang_named('Pascal'), $p, 'loop in Pascal';
    is_deeply $b->run_val('M'), [ 0, 1, 2, 3, 4 ], 'loop run';
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 4, [
            '=', ['[]', 'M', 'i'], 'i',
            '=', ['[]', 'M', 'i'], 'i',
        ]
    ]);
    my $p = q~for i := 0 to 4 do begin
  M[i] := i;
  M[i] := i;
end;~;
    is $b->to_lang_named('Pascal'), $p, 'loop in Pascal with begin-end';
}

{
    my $b = EGE::Prog::make_block([
        '=', 'a', 1,
        'for', 'i', 1, 3, [ '=', 'a', ['*', 'a', '2'] ]
    ]);
    my $p = q~a := 1
нц для i от 1 до 3
  a := a * 2
кц~;
    is $b->to_lang_named('Alg'), $p, 'loop in Alg';
    is $b->run_val('a'), 8, 'loop run';
}

{
    my $b = EGE::Prog::make_block([
        'if', 'a', [ '=', 'x', 7 ],
    ]);
    is $b->to_lang_named('Basic'), 'IF a THEN x = 7', 'if in Basic';
    is $b->to_lang_named('Perl'), "if (\$a) {\n  \$x = 7;\n}", 'if in Perl';
    is $b->run_val('x', { a => 0 }), undef, 'if (false) run';
    is $b->run_val('x', { a => 1 }), 7, 'if (true) run';
}

{
    my $b = EGE::Prog::make_block([
        'while', [ '>', 'a', 0 ], [ '=', 'a', [ '-', 'a', 1 ] ]
    ]);
    is $b->to_lang_named('Basic'),
        "DO WHILE a > 0\n  a = a - 1\nEND DO", 'while in Basic';
    is $b->to_lang_named('C'), "while (a > 0)\n  a = a - 1;", 'while in C';
    is $b->run_val('a', { a => 5 }), 0, 'while run';
}

{
    my $b = EGE::Prog::make_block([
        '=', 'x', '64',
        'while', [ '>', 'x', 7 ], [
            '=', 'x', [ '/', 'x', 2 ]
         ]
    ]);
    is $b->run_val('x'), 4, 'while run 2';
}

{
    my $b = EGE::Prog::make_block([
        'until', [ '==', 'a', 0 ], [ '=', 'a', [ '-', 'a', 1 ] ]
    ]);
    is $b->to_lang_named('Basic'),
        "DO UNTIL a = 0\n  a = a - 1\nEND DO", 'until in Basic';
    is $b->to_lang_named('C'), "while (!(a == 0))\n  a = a - 1;", 'until in C';
    is $b->run_val('a', { a => 5 }), 0, 'until run';
}

{
    my $e = make_expr([ '+', 'x', [ '-', 'y' ] ]);
    my $v = {};
    $e->gather_vars($v);
    is_deeply $v, { x => 1, y => 1 }, 'gather_vars';
}

sub check_sub {
    my ($lang, $block, $code, $name) = @_;
    is $block->to_lang_named($lang), join("\n", @$code), $name;
}

{
    my $b = EGE::Prog::make_block([
        'func', 'g', [ qw(a b) ], [
            '=', 'g', [ '-', 'a', 'b' ]
        ],
        '=', 'a', [ '()', 'g', 3, 2 ]
    ]);
    my $c = {
        Basic => [
            'FUNCTION g(a, b)',
            '  g = a - b',
            'END FUNCTION',
            '',
            'a = g(3, 2)',
        ],
        Alg => [
            'алг цел g(цел a, b)',
            'нач',
            '  g := a - b',
            'кон',
            '',
            'a := g(3, 2)',
        ],
        Pascal => [
            'function g(a, b: integer): integer;',
            'begin',
            '  g := a - b;',
            'end;',
            '',
            'a := g(3, 2);',
        ],
        C => [
            'int g(int a, int b) {',
            '  int g;',
            '  g = a - b;',
            '  return g;',
            '}',
            '',
            'a = g(3, 2);',
        ],
        Perl => [
            'sub g {',
            '  my $g;',
            '  my ($a, $b) = @_;',
            '  $g = $a - $b;',
            '  return $g;',
            '}',
            '',
            '$a = g(3, 2);',
        ],        
    };
    check_sub($_, $b, $c->{$_}, "function calling, definition in $_") for keys $c;
    is $b->run_val('a'), 1, 'run call function';
    is eval($b->to_lang_named('Perl')), 3 - 2, 'eval perl funtion';
}

{
    my $b = EGE::Prog::make_block([
        'func', 'f', [ qw(x y z) ], [],
        'func', 'f', [ qw(a b) ], [],
    ]);
    throws_ok sub { $b->run({}) }, qr/f/, 'function redefinition'
}

{
    my $b = EGE::Prog::make_block([
        '=', 'a', [ '()', 'g', 1, 2, 3 ],
    ]);
    throws_ok sub { $b->run({}) }, qr/g/, 'call undefined function';
}

{
    my $b = EGE::Prog::make_block([
        'func', 'f', [ qw(x y z) ], [],
        '=', 'a', [ '()', 'f', 1, 2 ],
    ]);
    throws_ok sub { $b->run({}) }, qr/f/, 'not enough arguments';
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 9, [
            'expr', [ 'print', 'i', 0 ]
        ]
    ]);
    my $c = {
        Basic => [
            'FOR i = 0 TO 9',
            '  PRINT i, 0',
            'NEXT i',
        ],
        Alg => [
            'нц для i от 0 до 9',
            '  вывод i, 0',
            'кц',
        ],
        Pascal => [
            'for i := 0 to 9 do',
            '  write(i, 0);',
        ],
        C => [
            'for (i = 0; i <= 9; ++i)',
            '  print(i, 0);',
        ],
        Perl => [
            'for ($i = 0; $i <= 9; ++$i) {',
            '  print($i, 0);',
            '}',
        ],
    };
    check_sub($_, $b, $c->{$_}, "print in $_") for keys $c;
    is $b->run_val('<out>'), join("\n", map $_ . ' ' . 0, 0 .. 9), 'run print';    
}

{
    my $e = make_expr([ '+', [ '*', 'x', 'x' ], [ '+', 'x', 2 ] ]);
    is $e->polinom_degree({ x => 1 }), 2, 'polinom degree'
}

{
    my $e = make_expr([ '+', 'x', 'xyz' ]);
    throws_ok sub { $e->polinom_degree({ x => 1 }) }, qr/Undefined variable xyz/, 'undefined var when calculating polinom degree' 
}

{
    my $e = make_expr([ '%', 'x', 'x' ]);
    throws_ok sub { $e->polinom_degree({ x => 1 }) }, qr/Polinom degree is unavaible for expr with operator: '%'/, 
        'calculating polinom degree of expr with \'%\'' 
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
    throws_ok sub { $b->complexity({ n => 1 }) }, qr/!=/, 'IfThen complexity for condition with \'!=\''
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
        'for', 'i', 0, 'n', [
            'for', 'j', 0, 'n', [
                'if', [ '==', 'i', 'j1' ], []
            ]
        ]
    ]);
    throws_ok sub { $b->complexity({ n => 1 }) }, qr/j1/, 'IfThen complexity for condition with not iterated var'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
            'if', [ '==', 'i', 2 ], []
        ]
    ]);
    throws_ok sub { $b->complexity({ n => 1 }) }, qr/such arguments/, 'IfThen complexity for condition with const'
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
    is $b->complexity({ n => 1} ), 4, 'multi IfThen complexity'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, ['*', [ '*', 'n', 'n' ], 'n'], [
            'if', [ '<=', 'i', 'n' ], [
                'for', 'j', 0, 'i', []
            ]
        ]
    ]);
    is $b->complexity({ n => 1} ), 3, 'IfThen complexity less condition'
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
    throws_ok sub { $b->complexity({ n => 1 }) }, qr/EGE::Prog::Const/, 'IfThen complexity without var in less condition'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 'n', [
            '=', 'i', 0     
        ]
    ]);
    throws_ok sub { $b->complexity({ n => 1 }) }, qr/i/, 'assign to iterator'
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, [ '*', 'n', 'n' ], [
            'for', 'j', 0, 'n', [
                'if', [ '==', 'i', 'j' ], [
                    'if', [ '<=', 'j', 10 ], [
                        'for', 'k', 0, ['*', ['*', 'i', 'i'], 'n'], []
                    ]
                ]
            ],
            'for', 'l', 0, 'i', []
        ]
    ]);
    my @mistakes_names = qw(var_as_const ignore_if_eq change_min ignore_if_less);
    my @ans = (4, 3, 7, 3, 3, 2, 4, 2, 4, 3, 8, 4, 4, 2, 4, 2);

    for (my $i = 1; $i < 2**@mistakes_names; $i++) {
        my %mistakes = map(($mistakes_names[$_] => $i/2**$_ % 2), (0..@mistakes_names-1));
        $mistakes{var_as_const} and $mistakes{var_as_const} = 'n';
        is $b->complexity({ n => 1 }, \%mistakes), $ans[$i], "complexity with mistakes:" .
            join ', ', map($mistakes{$_} ? $_ : (), @mistakes_names);
    }
}

{
    sub check_sql { is make_expr($_[0])->to_lang_named('SQL'), $_[1], "SQL $_[2]" }
    check_sql(
        [ '&&', [ '<=', 1, 'a' ], [ '<=', 'a', 'n' ] ],
        '1 <= a AND a <= n', 'AND');
    check_sql(
        [ '||', [ '!=', 1, 'a' ], [ '!', 'a' ] ],
        '1 <> a OR NOT a', 'OR NOT');
    check_sql(
        [ '&&', [ '||', 'x', 'y' ], [ '==', 'a', 1 ] ],
        '(x OR y) AND a = 1', 'priorities');
}

