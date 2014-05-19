use strict;
use warnings;
use utf8;

use Test::More tests => 68;
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
    is $e->to_lang_named('Logic'), '¬ (A > B)', 'not in logic';
    ok make_expr([ '||', [ '!', [ '&&', 1, 1 ] ], 1 ]);
}

{
    my $e = make_expr([ '+', 'a', 3 ]);
    is_deeply make_expr($e), $e, 'double make_expr';
}

{
    throws_ok { make_expr(['xyz'])->run({}) } qr/xyz/, 'undefined variable';
}

{
    my $e = make_expr([ '-', [ '-', 3, ['-', 2, 1 ] ] ]);
    is $e->run(), -2, 'visit_dfs before';
    $e->visit_dfs(sub { $_[0]->{op} = '+' if ($_[0]->{op} || '') eq '-' });
    is $e->run(), 6, 'visit_dfs after';
    is $e->count_if(sub { 1 }), 6, 'visit_dfs count all';
    is $e->count_if(sub { $_[0]->isa('EGE::Prog::Const') }), 3, 'count_if';
}

{
    my $b = make_expr([ '-', 3, 7 ]);
    is $b->run({}), -4;
    is $b->run({ _skip => 1 }), 3;
}

{
    my $e = make_expr([ '*', [ '+', 'a', 1 ], [ '-', 'b', 2 ] ]);
    is $e->to_lang_named('C'), '(a + 1) * (b - 2)', 'priorities 1';
}

{
    my $e = make_expr([ '+', [ '*', 'a', 1 ], [ '/', 'b', 2 ] ]);
    is $e->to_lang_named('C'), 'a * 1 + b / 2', 'priorities 2';
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

