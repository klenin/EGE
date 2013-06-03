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
	my ($reg, $format, $n) = cgen->generate_simple_code('add');
	my @variants = ($self->get_res($reg, $format));
	if ($n == 8 || cgen->{code}->[1]->[0] =~ /^(stc|clc)$/) {
		my $a = 2 ** $n;
		my $res = $variants[0];
		push @variants, rnd->pick($res+2, $res-2+$a) % $a, ($res+1) % $a, ($res-1+$a) % $a;
	}
	push @variants, proc->get_wrong_val($reg) while ($#variants < 3);
	$self->formated_variants($format, @variants);
	$self->{correct} = 0;
}

sub reg_value_logic {
	my $self = shift;
	my ($reg, $format, $n) = cgen->generate_simple_code('logic');
	my @variants = ($self->get_res($reg, $format));
	if (cgen->{code}->[1]->[0] eq 'test') {
		cgen->{code}->[1]->[0] = 'and';
		proc->run_code(cgen->{code});
		push @variants, proc->get_val($reg);
	}
	push @variants, proc->get_wrong_val($reg) while ($#variants < 3);
	$self->formated_variants($format, @variants);
	$self->{correct} = 0;
}

sub reg_value_shift {
	my $self = shift;
	my ($reg, $format, $n, $arg) = cgen->generate_simple_code('shift');
	my @variants = ($self->get_res($reg, $format));
	my $str = cgen->{code}->[1];
	my $use_cf = $str->[0] =~ /^(stc|clc)$/;
	$str = cgen->{code}->[2] if ($use_cf);

	my $make_wrong_answer = sub {
		my @old_cmd = @$str;
		$_[0]->();
		proc->run_code(cgen->{code});
		push @variants, proc->get_val($reg);
		$str->[$_] = $old_cmd[$_] for 0..$#old_cmd;
	};

	my $sgn = $arg >= 2 ** ($n-1);
	my $shift_right = ($str->[0] =~ /^(shr|sar)$/) && $sgn;
	$make_wrong_answer->(sub { $str->[0] =~ s/^rc/ro/ }) if ($use_cf);
	$make_wrong_answer->(sub { $str->[0] = {'sar' => 'shr', 'shr' => 'sar'}->{$str->[0]} }) if ($shift_right);
	push @variants, proc->get_wrong_val($reg) if (!$use_cf && !$shift_right);
	$make_wrong_answer->(sub { $str->[2] += $str->[2] == $n/8 ? $n/8 : rnd->pick($n/8, -$n/8) });
	$make_wrong_answer->(sub { $str->[0] =~ /^(\w\w)(l|r)$/; $str->[0] = $1.($2 eq 'l' ? 'r' : 'l') });
	$self->formated_variants($format, @variants);
	$self->{correct} = 0;
	$self->reg_value_shift() if (grep { $variants[$_] == $variants[0] } 1..$#variants);
}

sub reg_value_convert {
	my $self = shift;
	my ($reg, $reg1) = cgen->get_regs(32, 16);
	cgen->{code} = [];
	cgen->add_command('mov', $reg1, 15*2**12 + rnd->in_range(0, 2**12-1));
	cgen->generate_command('convert', $reg, $reg1);
	my @variants = ($self->get_res($reg, '%04Xh'));
	my $str = cgen->{code}->[1];
	$str->[0] = $str->[0] eq 'movsx' ? 'movzx' : 'movsx';
	proc->run_code(cgen->{code});
	push @variants, proc->get_val($reg);
	my $resz = $str->[0] eq 'movsx' ? $variants[0] : $variants[1] ;
	push @variants, 15*2**28 + $resz, 2**31 + $resz;
	$self->formated_variants('%08Xh', @variants);
	$self->{correct} = 0;
}

sub reg_value_jump {
	my $self = shift;
	cgen->{code} = [];
	my $reg = cgen->get_reg(8);
	cgen->generate_command('mov', $reg);
	cgen->generate_command('add', $reg);
	my $label = 'L';
	my $jmp = 'j'.{1 => 'n', 0 => ''}->{rnd->pick(0,1)}.rnd->pick(qw(c p z o s e g l ge le a b ae be));
	cgen->add_command($jmp, $label);
	cgen->add_command('add', $reg, 1);
	cgen->add_command($label.':');
	my $res = $self->get_res($reg, '%s');
	my @variants = ($res, rnd->pick($res+2, $res-2+256) % 256, ($res+1) % 256, ($res-1+256) % 256);
	$self->variants(@variants);
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
