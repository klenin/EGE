# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch03;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub reg_value_add {
	my $self = shift;
	my $reg = cgen->get_reg(32);
	my ($arg1, $arg2) = cgen->get_hex_args_add();
	my $res = $self->get_res('add', $reg, $arg1, $arg2);
	if (cgen->{code}->[2]) {
		my $a = 2 ** 32;
		my $res1 = rnd->pick($res+2, $res-2) % $a;
		$self->variants(map {sprintf '%08Xh', $_} ($res, $res1, ($res+1) % $a, ($res-1) % $a));
	}
	else {
		my ($res1, $res2, $res3);
		$_ = proc->get_wrong_val($reg) for ($res1, $res2, $res3);
		$self->variants(map {sprintf '%08Xh', $_} ($res, $res1, $res2, $res3));
	}
	$self->{correct} = 0;
}

sub reg_value_logic {
	my $self = shift;
	my $reg = cgen->get_reg(32);
	my ($arg1, $arg2) = cgen->get_hex_args_logic();
	my $res = $self->get_res('logic', $reg, $arg1, $arg2);
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
	$self->variants(map {sprintf '%08Xh', $_} ($res, $res1, $res2, $res3));
	$self->{correct} = 0;
}

sub reg_value_shift {
	my $self = shift;
	my $reg = cgen->get_reg(32);
	my ($arg1, $arg2) = cgen->get_hex_args_shift();
	my $sgn = $arg1 >= 2 ** 31;
	my $res = $self->get_res('shift', $reg, $arg1, $arg2);
	my ($res1, $res2, $res3);
	my $id = 1;
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
		cgen->{code}->[$id]->[2] = cgen->{code}->[$id]->[2] + 4;
		proc->run_code(cgen->{code});
		$res2 = proc->get_val($reg);
		cgen->{code}->[$id]->[2] = cgen->{code}->[$id]->[2] - 8;
		proc->run_code(cgen->{code});
		$res3 = proc->get_val($reg);
	}
	if ($shift_right) {
		cgen->{code}->[$id]->[0] = {'sar' => 'shr', 'shr' => 'sar'}->{cgen->{code}->[$id]->[0]};
		proc->run_code(cgen->{code});
		$res1 = proc->get_val($reg);
		cgen->{code}->[$id]->[2] += cgen->{code}->[$id]->[2] == 4 ? 4 : rnd->pick(4, -4);
		proc->run_code(cgen->{code});
		$res2 = proc->get_val($reg);
		cgen->{code}->[$id]->[0] = {'sar' => 'shr', 'shr' => 'sar'}->{cgen->{code}->[$id]->[0]};
		proc->run_code(cgen->{code});
		$res3 = proc->get_val($reg);
	}
	$self->variants(map {sprintf '%08Xh', $_} ($res, $res1, $res2, $res3));
	$self->{correct} = 0;
}

sub get_res {
	my ($self, $type, $reg, $arg1, $arg2) = @_;
	cgen->{code} = [];
	cgen->generate_command('mov', $reg, $arg1);
	cgen->generate_command($type, $reg, $arg2);
	proc->run_code(cgen->{code});
	my $res = proc->get_val($reg);
	my $code_txt = cgen->get_code_txt('%08Xh');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt в $reg будет содержаться значение:
QUESTION
;
	$res;
}

sub reg_value_convert {
	my $self = shift;
	cgen->{code} = [];
	my ($reg, $reg1) = cgen->get_regs(32, 16);
	cgen->add_command('mov', $reg1, 15*2**12 + rnd->in_range(0, 2**12-1));
	cgen->generate_command('convert', $reg, $reg1);
	proc->run_code(cgen->{code});
	my $res = proc->get_val($reg);
	my $code_txt = cgen->get_code_txt('%04Xh');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt в $reg будет содержаться значение:
QUESTION
;
	my ($res1, $res2, $res3);
	cgen->{code}->[1]->[0] = cgen->{code}->[1]->[0] eq 'movsx' ? 'movzx' : 'movsx';
	proc->run_code(cgen->{code});
	$res1 = proc->get_val($reg);
	$res2 = cgen->{code}->[1]->[0] eq 'movzx' ? 15*2**28 + $res1 : 15*2**28 + $res;
	$res3 = cgen->{code}->[1]->[0] eq 'movzx' ? 2**31 + $res1 : 2**31 + $res;
	$self->variants(map {sprintf '%08Xh', $_} ($res, $res1, $res2, $res3));
	$self->{correct} = 0;
}

1;
