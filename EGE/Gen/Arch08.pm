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
    cgen->set_commands(
        cgen->random_mov($reg),
        (rnd->coin ? [ 'sub', $reg, rnd->in_range(1, 255) ] : [ 'neg', $reg ]),
        [ '<i>jcc</i>', $label ],
        [ 'add', $reg, 1 ],
        [ "$label:" ]
    );
    my $jcc = \cgen->{code}->[2]->[0];
    my $code_txt = cgen->get_code_txt('%s');
    my $fmt =
        "В результате выполнения кода $code_txt в $reg " .
        "будет содержаться значение %d, если $$jcc заменить на:";

    my @jumps = map rnd->pick_n(2, @$_),
        [ qw(jc jz jo js jnc jnz jno jns) ],
        [ qw(je jne jl jnge jle jng jg jnle jge jnl jb jnae jbe jna ja jnbe jae jnb) ];

    my @res = map {
        $$jcc = $_;
        proc->run_code(cgen->{code})->get_val($reg);
    } @jumps;
    my $good = rnd->pick(@res);
    if (0 == grep $_ != $good, @res) {
        $$jcc =~ s/^j([n]?)(\w+)$/'j' . ($1 ? '' : 'n') . $2/e;
        $res[-1] = proc->run_code(cgen->{code})->get_val($reg);
    }
    $self->{correct} = [ map $_ == $good, @res ];
    $self->{text} = sprintf $fmt, $good;
    $self->variants(@jumps);
}

1;
