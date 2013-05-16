# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch09;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::AsmCodeGenerate;

sub reg_value_before_loopnz {
	my $self = shift;
	cgen->{code} = [];
	my $reg = cgen->get_reg(8, 'not_ecx');
	my $arg = rnd->in_range(3, 254);
	my $res = rnd->in_range(1, $arg-1);
	cgen->add_command('mov', 'cl', $arg);
	my $label = 'L';
	cgen->add_command($label.":");
	cgen->add_command('sub', $reg, 1);
	cgen->add_command('loopnz', $label);
	my $cor = $arg - $res;
	$self->variants($cor, $cor+1, $cor-1, rnd->pick($cor+2, $cor-2));
	$self->{correct} = 0;
	my $code_txt = cgen->get_code_txt('%s');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt сl содержит значение $res. До выполнения кода в $reg содержалось значение:
QUESTION
;
}

sub zero_fill {
	my $self = shift;
	cgen->{code} = [];
	my $reg = cgen->get_reg(32, 'not_ecx');
	my $arg = rnd->in_range(1, 25)*10;
	cgen->add_command('mov', 'ecx', $arg);
	cgen->add_command('mov', $reg, 0);
	my $cmd = rnd->pick('stosb', 'stosw', 'stosd');
	cgen->add_command('rep', $cmd);
	my $code_txt = cgen->get_code_txt('%s');
	$self->{text} = <<QUESTION
Последовательность команд $code_txt заполнит нулями:
QUESTION
;
	$self->formated_variants('%s байт', 0, $arg, $arg*2, $arg*4);
	$self->{correct} = {stosb => 1, stosw => 2, stosd => 3}->{$cmd};
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
