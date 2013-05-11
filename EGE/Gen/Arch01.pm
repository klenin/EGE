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
	my ($reg, $format, $n) = cgen->init_params('add');
	my $res = $self->get_res($reg, $format);
	if ($n == 8 || cgen->{code}->[2]) {
		my $a = 2 ** $n;
		my $res1 = rnd->pick($res+2, $res-2) % $a;
		$self->variants(map {sprintf $format, $_} ($res, $res1, ($res+1) % $a, ($res-1) % $a));
	}
	else {
		my ($res1, $res2, $res3);
		$_ = proc->get_wrong_val($reg) for ($res1, $res2, $res3);
		$self->variants(map {sprintf $format, $_} ($res, $res1, $res2, $res3));
	}
	$self->{correct} = 0;
}

sub reg_value_logic {
	my $self = shift;
	my ($reg, $format, $n) = cgen->init_params('logic');
	my $res = $self->get_res($reg, $format);
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
	$self->variants(map {sprintf $format, $_} ($res, $res1, $res2, $res3));
	$self->{correct} = 0;
}

sub reg_value_shift {
	my $self = shift;
	my ($reg, $format, $n, $arg) = cgen->init_params('shift');
	my $res = $self->get_res($reg, $format);
	my ($res1, $res2, $res3);
	my $id = 1;
	my $sgn = $arg >= 2 ** ($n-1);
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
		cgen->{code}->[$id]->[2] = cgen->{code}->[$id]->[2] + $n/8;
		proc->run_code(cgen->{code});
		$res2 = proc->get_val($reg);
		cgen->{code}->[$id]->[2] = cgen->{code}->[$id]->[2] - 2*$n/8;
		proc->run_code(cgen->{code});
		$res3 = proc->get_val($reg);
	}
	if ($shift_right) {
		cgen->{code}->[$id]->[0] = {'sar' => 'shr', 'shr' => 'sar'}->{cgen->{code}->[$id]->[0]};
		proc->run_code(cgen->{code});
		$res1 = proc->get_val($reg);
		my $shift = cgen->{code}->[$id]->[2];
		cgen->{code}->[$id]->[2] += $shift == $n/8 ? $n/8 : rnd->pick($n/8, -$n/8);
		proc->run_code(cgen->{code});
		$res2 = proc->get_val($reg);
		cgen->{code}->[$id]->[0] = {'sar' => 'shr', 'shr' => 'sar'}->{cgen->{code}->[$id]->[0]};
		proc->run_code(cgen->{code});
		$res3 = proc->get_val($reg);
	}
	$self->variants(map {sprintf $format, $_} ($res, $res1, $res2, $res3));
	$self->{correct} = 0;
}

sub reg_value_convert {
	my $self = shift;
	my ($reg, $reg1) = cgen->get_regs(32, 16);
	cgen->{code} = [];
	cgen->add_command('mov', $reg1, 15*2**12 + rnd->in_range(0, 2**12-1));
	cgen->generate_command('convert', $reg, $reg1);
	my $res = $self->get_res($reg, '%04Xh');
	my ($res1, $res2, $res3);
	cgen->{code}->[1]->[0] = cgen->{code}->[1]->[0] eq 'movsx' ? 'movzx' : 'movsx';
	proc->run_code(cgen->{code});
	$res1 = proc->get_val($reg);
	$res2 = cgen->{code}->[1]->[0] eq 'movzx' ? 15*2**28 + $res1 : 15*2**28 + $res;
	$res3 = cgen->{code}->[1]->[0] eq 'movzx' ? 2**31 + $res1 : 2**31 + $res;
	$self->variants(map {sprintf '%08Xh', $_} ($res, $res1, $res2, $res3));
	$self->{correct} = 0;
}

sub reg_value_jump {
	my $self = shift;
	cgen->{code} = [];
	my $reg = cgen->get_reg(8);
	cgen->generate_command('mov', $reg);
	cgen->generate_command('add', $reg);
	my $l = 'L';
	my $jmp = 'j'.{1 => 'n', 0 => ''}->{rnd->pick(0,1)}.rnd->pick(qw(c p z o s e g l ge le a b ae be));
	cgen->add_command($jmp, $l);
	cgen->add_command('add', $reg, 1);
	cgen->add_command($l.':');
	my $res = $self->get_res($reg, '%s');
	my $res1 = rnd->pick($res+2, $res-2) % 256;
	$self->variants($res, $res1, ($res+1) % 256, ($res-1) % 256);
	$self->{correct} = 0;
}

sub get_res {
	my ($self, $reg, $format) = @_;
	proc->run_code(cgen->{code});
	my $res = proc->get_val($reg);
	my $code_txt = cgen->get_code_txt($format);
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt в $reg будет содержаться значение:
QUESTION
;
	$res;
}

1;
