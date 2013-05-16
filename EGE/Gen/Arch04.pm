# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch04;
use base 'EGE::GenBase::MultipleChoiceFixedVariants';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub choose_commands {
	my $self = shift;
	my ($reg1, $reg2) = cgen->get_regs(8, 8);
	my ($arg1, $arg2, $arg3, $cmd1, $cmd2, $cmd3);
	map { $_ = rnd->in_range(1, 255) } ($arg1, $arg2, $arg3);
	map { $_ = rnd->pick('add', 'sub') } ($cmd1, $cmd2, $cmd3);
	$self->variants(map { $_ = "<code>$_</code>" } ("mov $reg1, $arg1", "$cmd1 $reg1, $arg2",
		"mov $reg2, $reg1", "$cmd2 $reg1, $arg3", "$cmd3 $reg1, $reg2"));
	my $commands = [ ['mov', $reg1, $arg1],
					[$cmd1, $reg1, $arg2],
					['mov', $reg2, $reg1],
					[$cmd2, $reg1, $arg3],
					[$cmd3, $reg1, $reg2]
					];
	my @res_arr = ();
	my @correct_arr = ( [1, 0, 1, 1, 1],
						[1, 1, 1, 0, 1],
						[1, 0, 1, 0, 1]
					);
	my @incorrect_arr = ( [1, 1, 1, 1, 1],
						[1, 0, 0, 0, 0],
						[1, 1, 0, 0, 0],
						[1, 1, 0, 1, 0]
					);
	push @res_arr, $self->get_res($commands, $_, $reg1) for (@correct_arr, @incorrect_arr);
	my @ids = ();
	for my $i (0..$#correct_arr) {
		push @ids, $i if (! grep {$res_arr[$i] == $res_arr[$_] && $i != $_ } (0..$#res_arr));
	}
	$self->choose_commands(), return if ($#ids == -1);
	my $id = rnd->pick(@ids);
	$self->{text} = <<QUESTION
Выделите подмножество команд так, чтобы после выполнения полученного кода в регистре $reg1 содержалось значение $res_arr[$id]
QUESTION
;
	$self->{correct} = $correct_arr[$id];
}

sub get_res {
	my ($self, $commands, $arr, $reg) = @_;
	cgen->{code} = [];
	for my $i (0..$#{$commands}) {
		cgen->add_command(@{$commands->[$i]}) if ($arr->[$i]);
	}
	proc->run_code(cgen->{code});
	proc->get_val($reg);
}

1;
