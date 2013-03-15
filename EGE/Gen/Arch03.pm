# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch03;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;
use POSIX qw/ceil/;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub reg_value_add {
	my $self = shift;
	my $reg = cgen->get_reg(32);
	my ($arg1, $arg2) = $self->get_args_add();
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
	my ($arg1, $arg2) = $self->get_args_logic();
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
	my ($arg1, $arg2) = $self->get_args_shift();
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

sub get_args_add {
	my ($arg1, $arg2) = (0, 0);
	for (1..7) {
		my $sum = rnd->in_range(0, 15);
		my $n = rnd->in_range(ceil($sum/2), $sum);
		$arg1 = $arg1*16 + $n;
		$arg2 = $arg2*16 + $sum - $n;
	}
	$arg1 += rnd->in_range(0, 15) * 16**7;
	$arg2 += rnd->in_range(0, 15) * 16**7;
	($arg1, $arg2);
}

sub get_args_logic {
	my @arr = (0, 0);
	for (1..8) {
		my $n1 = rnd->pick(0, 15);
		my $n2 = rnd->in_range(0, 15);
		my ($i, $j) = rnd->pick_n(2, (0, 1));
		$arr[$i] = $arr[$i]*16 + $n1;
		$arr[$j] = $arr[$j]*16 + $n2;
	}	
	@arr;
}

sub get_args_shift {
	my $arg = 0;
	$arg = $arg*16 + rnd->in_range(0, 15) for (1..8);
	($arg, rnd->pick(4,8,12,16));
}

sub get_res {
	my ($self, $type, $reg, $arg1, $arg2) = @_;
	cgen->{code} = [];
	cgen->generate_command('mov', $reg, $arg1);
	cgen->generate_command($type, $reg, $arg2);
	proc->run_code(cgen->{code});
	my $res = proc->get_val($reg);
	my $code_txt = cgen->get_code_txt('hex');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt в $reg будет содержаться значение:
QUESTION
;
	$res;
}

1;
