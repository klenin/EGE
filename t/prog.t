use strict;
use warnings;

use Test::More tests => 26;

use lib '..';
use EGE::Prog qw(make_block make_expr);

{
    my @t = (
        [ '+', 4, 5 ],    9,
        [ '*', 4, 5 ],   20,
        [ '/', 4, 5 ],  0.8,
        [ '%', 14, 5 ],   4,
        [ '//', 14, 5 ],  2,
        [ '-', 4 ],      -4,
    );
    is(make_expr(shift @t)->run({}), shift @t) while @t;
    my $env = { a => '2', b => '3' };
    is(make_expr([ '*', 'a', ['+', 'b', 7 ] ])->run($env), 20);
}

{
    my $b = make_expr([ '-', 3, 7 ]);
    is($b->count_ops, 1);
    is($b->run({}), -4);
    is($b->run({ _skip => 1 }), 3);
    is($b->run({ _replace_op => { '-' => '*' } }), 21);
}

{
    my $b = make_block([]);
    is($b->to_lang($_), '', $_) for keys %{EGE::Prog::lang_names()};
}

{
    my $b = make_block([ '=', 'x', 99 ]);
    is($b->to_lang('Alg'), 'x := 99');
    is($b->run_val('x'), 99);
}

{
    my $b = make_block([ '=', 'x', 3, '=', 'y', 'x' ]);
    is($b->run_val('y'), 3);
}

{
    my $m = 5;
    my $b = make_block([ '=', 'x', ['+', \$m, 1 ] ]);
    is($b->run_val('x'), 6);
    $m = 10;
    is($b->run_val('x'), 11);
}

{
    my $b = make_block([ '#', { 'Basic' => 'basic text' }]);
    is($b->to_lang('Basic'), 'basic text');
    is($b->to_lang('C'), '');
}

{
    my $b = EGE::Prog::make_block([ '=', [ '[]', 'A', 2 ], 5 ]);
    is($b->to_lang('Pascal'), 'A[2] := 5;');
    is_deeply($b->run_val('A'), [ undef, undef, 5 ]);
}

{
    my $b = EGE::Prog::make_block([
        'for', 'i', 0, 4, [ '=', ['[]', 'M', 'i'], 'i' ]
    ]);
    my $p = q~for i := 0 to 4 do begin
  M[i] := i;
end;~;
    is($b->to_lang('Pascal'), $p, 'loop in Pascal');
    is_deeply($b->run_val('M'), [ 0, 1, 2, 3, 4 ], 'loop run');
}
