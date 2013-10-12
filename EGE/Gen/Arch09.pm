# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch09;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NumText;
use EGE::Asm::AsmCodeGenerate;

sub reg_value_before_loopnz {
    my $self = shift;
    my $reg = cgen->get_reg(8, 'not_ecx');
    my $arg = rnd->in_range(3, 254);
    my $res = rnd->in_range(1, $arg - 1);
    my $label = 'L';
    cgen->clear;
    cgen->add_commands(
        [ 'mov', 'cl', $arg ],
        [ "$label:" ],
        [ 'sub', $reg, 1 ],
        [ 'loopnz', $label ],
    );
    $self->variants(map $arg - $res + $_, 0, +1, -1, rnd->pick(+2, -2));
    my $code_txt = cgen->get_code_txt('%s');
    $self->{text} =
        "В результате выполнения кода $code_txt регистр <code>cl</code> содержит значение $res. " .
        "До выполнения кода в <code>$reg</code> содержалось значение:";
}

sub zero_fill {
    my $self = shift;
    my $reg = cgen->get_reg(32, 'not_ecx');
    my $arg = rnd->in_range(1, 25) * 10;
    my @cmds = qw(stosb stosw stosd);
    $self->{correct} = rnd->in_range(1, scalar @cmds);
    cgen->clear;
    cgen->add_commands(
        [ 'mov', 'ecx', $arg ],
        [ 'mov', $reg, 0 ],
        [ 'rep', $cmds[$self->{correct} - 1] ],
    );
    my $code_txt = cgen->get_code_txt('%s');
    $self->{text} = "Последовательность команд $code_txt заполнит нулями:";
    $self->variants(map EGE::NumText::num_bytes($_), 0, map $arg * 2 ** $_, 0..$#cmds);
}

sub stack {
	my $self = shift;
	cgen->{code} = [];
	my $reg = cgen->get_reg(32, 'not_ecx');
	my $arg = rnd->in_range(10, 255);
	my $off = rnd->in_range(1, $arg/2-2);
	cgen->add_command('mov', 'ecx', $arg);
	my $label = 'L';
	cgen->add_command($label.":");
	cgen->add_command('push', 'ecx');
	cgen->add_command('loop', $label);
	cgen->add_command('mov', $reg, "[esp+$off*4]");
	my $code_txt = cgen->get_code_txt('%s');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt в $reg будет содержаться значение:
QUESTION
;
	$self->variants($off + 1, $off, $arg - $off, rnd->pick($arg-$off+1, $arg-$off-1));
	$self->{correct} = 0;
}

1;
