# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch05;
use base 'EGE::GenBase::Sortable';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub sort_commands {
	my $self = shift;
	my ($reg1, $reg2, $arg, $cmd_shift, $hex_val) = $self->init_params(8);
	my $cmd = rnd->pick('add', 'sub', 'and', 'or', 'xor');
	$self->formated_variants('<code>%s</code>', "mov $reg1, $hex_val", "$cmd_shift $reg1, 4", "mov $reg2, $reg1", "$cmd $reg1, $reg2");
	my $commands = [
		['mov', $reg1, $arg],
		[$cmd_shift, $reg1, 4],
		['mov', $reg2, $reg1],
		[$cmd, $reg1, $reg2]
	];
	my @correct_arr = (
		[0, 1, 2, 3],
		[0, 2, 1, 3],
		[0, 2, 3, 1]
	);
	my @res_arr;
	push @res_arr, $self->get_res($commands, $_, $reg1) for (@correct_arr);
	$self->sort_commands if (!$self->choose_correct($reg1, \@res_arr, \@correct_arr, '%02Xh'));
}

sub sort_commands_stack {
	my $self = shift;
	my ($reg1, $reg2, $arg, $cmd_shift, $hex_val) = $self->init_params(16);
	$self->formated_variants('<code>%s</code>', "mov $reg1, $hex_val", "$cmd_shift $reg1, 4", "push $reg1", "pop $reg2", "add $reg1, $reg2");
	my $commands = [
		['mov', $reg1, $arg],
		[$cmd_shift, $reg1, 4],
		['push', $reg1],
		['pop', $reg2],
		['add', $reg1, $reg2]
	];
	my @correct_arr = (
		[0, 1, 2, 3, 4],
		[0, 2, 3, 4, 1]
	);
	my @incorrect_arr = ( [0, 2, 3, 1, 4] );
	my @res_arr;
	push @res_arr, $self->get_res($commands, $_, $reg1) for (@correct_arr, @incorrect_arr);
	$self->sort_commands_stack if (!$self->choose_correct($reg1, \@res_arr, \@correct_arr, '%04Xh'));
}

sub init_params {
	my ($self, $n) = @_;
	my ($reg1, $reg2) = cgen->get_regs($n, $n);
	my $arg = rnd->in_range(1, 15) * 16 + rnd->in_range(1, 15);
	my $cmd_shift = rnd->pick('shl', 'shr', 'sal', 'sar', 'rol', 'ror');
	my $hex_val = sprintf '%02Xh', $arg;
	($reg1, $reg2, $arg, $cmd_shift, $hex_val);
}

sub choose_correct {
	my ($self, $reg1, $res_arr, $correct_arr, $format) = @_;
	my @ids;
	for my $i (0..$#{$correct_arr}) {
		push @ids, $i if (! grep {$res_arr->[$i] == $res_arr->[$_] && $i != $_ } (0..$#{$res_arr}));
	}
	return '' if ($#ids == -1);
	my $id = rnd->pick(@ids);
	my $hex_val = sprintf $format, $res_arr->[$id];
	$self->{text} = <<QUESTION
Расположите команды в такой последовательности, чтобы после их выполнения в регистре $reg1 содержалось значение $hex_val:
QUESTION
;
	$self->{correct} = $correct_arr->[$id];
	$self;
}

sub get_res {
	my ($self, $commands, $arr, $reg) = @_;
	cgen->{code} = [];
	cgen->add_command(@{$commands->[$_]}) for (@$arr);
	proc->run_code(cgen->{code});
	proc->get_val($reg);
}

1;
