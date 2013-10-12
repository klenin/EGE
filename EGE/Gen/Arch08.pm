# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch08;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub choose_jump {
    my $self = shift;
    my $reg = cgen->get_reg(8);
    my $label = 'L';
    my $jcc = '<i>jcc</i>';
    cgen->clear;
    cgen->generate_command('mov', $reg);
    cgen->add_commands(
        (rnd->coin ? [ 'sub', $reg, rnd->in_range(1, 255) ] : [ 'neg', $reg ]),
        [ $jcc, $label ],
        [ 'add', $reg, 1 ],
        [ "$label:" ]
    );
    my $code_txt = cgen->get_code_txt('%s');

    my @jumps = map rnd->pick_n(2, @$_),
        [ qw(jc jz jo js jnc jnz jno jns) ],
        [ qw(je jne jl jnge jle jng jg jnle jge jnl jb jnae jbe jna ja jnbe jae jnb) ];
    my @res = map {
        cgen->{code}->[2]->[0] = $_;
        proc->run_code(cgen->{code})->get_val($reg);
    } @jumps;
    my $good = rnd->pick(@res);
    $self->{correct} = [ map $_ == $good, @res ];

    $self->{text} =
        "В результате выполнения кода $code_txt в $reg " .
        "будет содержаться значение $good, если $jcc заменить на:";
    $self->variants(@jumps);
}

1;
