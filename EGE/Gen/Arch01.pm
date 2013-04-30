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
	cgen->{code} = [];
	my $reg = cgen->get_reg(8);
	my $arg = rnd->in_range(1, 15) * 16 + rnd->in_range(1, 15);
	cgen->generate_command('mov', $reg, $arg);
	cgen->generate_command('shift', $reg);
	my $res = $self->get_res($reg);
	my ($res1, $res2, $res3);
	my $id = 1;
	my $sgn = $arg >= 128;
	my $use_cf = cgen->{code}->[1]->[0] eq 'stc' || cgen->{code}->[1]->[0] eq 'clc';
	my $shift_right = (cgen->{code}->[1]->[0] eq 'shr' || cgen->{code}->[1]->[0] eq 'sar') && $sgn;
	my $other = !$use_cf && !$shift_right;
	if ($use_cf) {
		$id = 2;
		s/c/o/ for (cgen->{code}->[$id]->[0]);
		proc->run_code(cgen->{code});
		$res1 = proc->get_val($reg);
		s/o/c/ for (cgen->{code}->[$id]->[0]);
	}
	$res1 = proc->get_wrong_val($reg) if ($other);
	if (!$shift_right) {
		cgen->{code}->[$id]->[2] = (cgen->{code}->[$id]->[2] + 1) % 8;
		proc->run_code(cgen->{code});
		$res2 = proc->get_val($reg);
		cgen->{code}->[$id]->[2] = (cgen->{code}->[$id]->[2] - 2) % 8;
		proc->run_code(cgen->{code});
		$res3 = proc->get_val($reg);
	}
	if ($shift_right) {
		cgen->{code}->[$id]->[0] = {'sar' => 'shr', 'shr' => 'sar'}->{cgen->{code}->[$id]->[0]};
		proc->run_code(cgen->{code});
		$res1 = proc->get_val($reg);
		my $shift = cgen->{code}->[$id]->[2];
		cgen->{code}->[$id]->[2] += $shift == 1 ? 1 : rnd->pick(1, -1);
		proc->run_code(cgen->{code});
		$res2 = proc->get_val($reg);
		cgen->{code}->[$id]->[0] = {'sar' => 'shr', 'shr' => 'sar'}->{cgen->{code}->[$id]->[0]};
		proc->run_code(cgen->{code});
		$res3 = proc->get_val($reg);
	}
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

sub reg_value_jump {
	my $self = shift;
	my $reg = $self->get_reg('add');
	my $l = 'L';
	my $jmp = 'j'.{1 => 'n', 0 => ''}->{rnd->pick(0,1)}.rnd->pick(qw(c p z o s e g l ge le a b ae be));
	cgen->add_command($jmp, $l);
	cgen->add_command('add', $reg, 1);
	cgen->add_command($l.':');
	my $res = $self->get_res($reg);
	my $res1 = rnd->pick($res+2, $res-2) % 256;
	$self->variants($res, $res1, ($res+1) % 256, ($res-1) % 256);
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
	my $code_txt = cgen->get_code_txt('%s');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt в $reg будет содержаться значение:
QUESTION
;
	$res;
}

1;
