use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

use lib '..';
use EGE::Asm::AsmCodeGenerate;
use EGE::Prog qw(make_expr);

{
    is cgen->format_command([ 'mov', 'ax', 65536 ], '%d'), 'mov ax, 65536', 'format word';
    is cgen->format_command([ 'mov', 'ax', 65535 ], '%04xh'), 'mov ax, 0ffffh', 'format word hex 1';
    is cgen->format_command([ 'mov', 'ax', 32767 ], '%04xh'), 'mov ax, 7fffh', 'format word hex 2';
}

{
    is EGE::Asm::AsmCodeGenerate::make_reg(16, 'c'), 'cx', 'make_reg';
}

{
    cgen->clear;
    is cgen->compile(make_expr [ '+', 3, 5 ]), 'eax', 'compile + 1';
    is_deeply cgen->{code}, [ [ 'mov', 'eax', 3 ], [ 'add', 'eax', 5 ] ], 'compile + 2';
    is cgen->compile(make_expr [ '+', 3, 5 ]), 'ebx', 'compile + ebx 1';

    cgen->clear;
    is cgen->compile(make_expr [ '-', 3, [ '*', 4, 5 ] ]), 'eax', 'compile -* 1';
    is_deeply cgen->{code}, [
        [ 'mov', 'eax', 3 ],
        [ 'mov', 'ebx', 4 ],
        [ 'imul', 'ebx', 5 ],
        [ 'sub', 'eax', 'ebx' ],
    ], 'compile -* 2';

    cgen->clear;
    is cgen->compile(make_expr [ '^', [ '|', [ '&', 3, 5 ], 6 ], 7 ]), 'eax', 'compile ^|& 1';
    is_deeply cgen->{code}, [
        [ 'mov', 'eax', 3 ],
        [ 'and', 'eax', 5 ],
        [ 'or', 'eax', 6 ],
        [ 'xor', 'eax', 7 ],
    ], 'compile ^|& 2';
}

{
    cgen->clear;
    is cgen->compile(make_expr [ '+',
        [ '+', [ '+', 101, 102 ], [ '+', 103, 104 ] ], [ '+', 12, 13 ] ]), 'eax', 'compile free reg 1';
    is_deeply cgen->{code}, [
        [ 'mov', 'eax', 101 ],
        [ 'add', 'eax', 102 ],
        [ 'mov', 'ebx', 103 ],
        [ 'add', 'ebx', 104 ],
        [ 'add', 'eax', 'ebx' ],
        [ 'mov', 'ebx', 12 ],
        [ 'add', 'ebx', 13 ],
        [ 'add', 'eax', 'ebx' ],
    ], 'compile free reg 2';
}

{
    cgen->clear;
    throws_ok { cgen->move_command(0, 0) } qr/from/, 'bad from';
    cgen->add_commands(
        [ 'mov', 'eax', 1 ],
        [ 'add', 'eax', 2 ],
        [ 'mov', 'ebx', 3 ],
        [ 'add', 'ebx', 4 ],
    );
    throws_ok { cgen->move_command(3, 5) } qr/to/, 'bad to';
    cgen->move_command(3, 0);
    is_deeply cgen->{code}, [
        [ 'add', 'ebx', 4 ],
        [ 'mov', 'eax', 1 ],
        [ 'add', 'eax', 2 ],
        [ 'mov', 'ebx', 3 ],
    ], 'move_command 3->0';
    cgen->move_command(2, 1);
    is_deeply cgen->{code}, [
        [ 'add', 'ebx', 4 ],
        [ 'add', 'eax', 2 ],
        [ 'mov', 'eax', 1 ],
        [ 'mov', 'ebx', 3 ],
    ], 'move_command 2->1';
    cgen->move_command(0, 4);
    is_deeply cgen->{code}, [
        [ 'add', 'eax', 2 ],
        [ 'mov', 'eax', 1 ],
        [ 'mov', 'ebx', 3 ],
        [ 'add', 'ebx', 4 ],
    ], 'move_command 0->4';
}

{
    cgen->clear;
    throws_ok { cgen->free_register('eax') } qr/eax/, 'register not allocated';
}

{
    my $expr = 1;
    $expr = [ '-', $_, $expr ] for 1..8;
    cgen->clear;
    is cgen->compile(make_expr $expr), 'eax', 'compile deep';

    $expr = [ '-', 9, $expr ];
    throws_ok { cgen->compile(make_expr $expr) } qr/registers/, 'not enough registers';
}

