# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch01;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub reg_value_add {
	my $self = shift;
	my $reg = $self->get_reg('add');
	my $res = $self->get_res($reg);
	my $res1 = rnd->pick($res+2, $res-2) % 256;
	$self->variants($res, $res1, ($res+1) % 256, ($res-1) % 256);
	$self->{correct} = 0;
}

sub reg_value_logic {
	my $self = shift;
	my $reg = $self->get_reg('logic');
	my $res = $self->get_res($reg);
	my ($res1, $res2, $res3);
	if (cgen->{code}->[1]->[0] eq 'test') {
		cgen->{code}->[1]->[0] = 'and';
		proc->run_code(cgen->{code});
		$res1 = proc->get_val($reg);
	}
	else {
		$res1 = proc->get_wrong_val($reg);
	}
	$res2 = proc->get_wrong_val($reg);
	$res3 = proc->get_wrong_val($reg);	
	$self->variants($res, $res1, $res2, $res3);
	$self->{correct} = 0;
}

sub reg_value_shift {
	my $self = shift;
	my $reg = $self->get_reg('shift');
	my $res = $self->get_res($reg);
	my ($res1, $res2, $res3);
	my $id;
	if (cgen->{code}->[1]->[0] eq 'stc' || cgen->{code}->[1]->[0] eq 'clc') {
		s/c/o/ for (cgen->{code}->[2]->[0]);
		proc->run_code(cgen->{code});
		$res1 = proc->get_val($reg);
		s/o/c/ for (cgen->{code}->[2]->[0]);
		$id = 2;
	}
	else {
		$id = 1;
		$res1 = proc->get_wrong_val($reg);
	}
	cgen->{code}->[$id]->[2] = (cgen->{code}->[$id]->[2] + 1) % 8;
	proc->run_code(cgen->{code});
	$res2 = proc->get_val($reg);
	cgen->{code}->[$id]->[2] = (cgen->{code}->[$id]->[2] - 2) % 8;
	proc->run_code(cgen->{code});
	$res3 = proc->get_val($reg);
	$self->variants($res, $res1, $res2, $res3);
	$self->{correct} = 0;
}

sub reg_value_convert {
	my $self = shift;
	cgen->{code} = [];
	my $reg = cgen->get_reg(16);
	my $reg1 = cgen->get_reg(8);
	cgen->generate_command('mov', $reg1, 128, 255);
	cgen->generate_command('convert', $reg, $reg1);
	my $res = $self->get_res($reg);
	my ($res1, $res2, $res3);
	cgen->{code}->[1]->[0] = cgen->{code}->[1]->[0] eq 'movsx' ? 'movzx' : 'movsx';
	proc->run_code(cgen->{code});
	$res1 = proc->get_val($reg);
	$res2 = cgen->{code}->[1]->[0] eq 'movzx' ? 2**15 + $res1 : 2**15 + $res;
	$self->variants($res, $res1, $res2);
	$self->{correct} = 0;
}

sub get_reg {
	my ($self, $type) = @_;
	cgen->{code} = [];
	my $reg = cgen->get_reg(8);
	cgen->generate_command('mov', $reg);
	cgen->generate_command($type, $reg);
	$reg;
}

sub get_res {
	my ($self, $reg) = @_;
	proc->run_code(cgen->{code});
	my $res = proc->get_val($reg);
	my $code_txt = cgen->get_code_txt('dec');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt в $reg будет содержаться значение:
QUESTION
;
	$res;
}

1;
