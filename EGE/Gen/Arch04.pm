# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch04;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;
use EGE::Gen::Arch03;

sub flags_value_add {
	my $self = shift;
	my ($arg1, $arg2) = EGE::Gen::Arch03->get_args_add();
	$self->flags_value('add', $arg1, $arg2);
}

sub flags_value_logic {
	my $self = shift;
	my ($arg1, $arg2) = EGE::Gen::Arch03->get_args_logic();
	$self->flags_value('logic', $arg1, $arg2);
}

sub flags_value_shift {
	my $self = shift;
	my ($arg1, $arg2) = EGE::Gen::Arch03->get_args_shift();
	$self->flags_value('shift', $arg1, $arg2);
}

sub flags_value {
	my ($self, $type, $arg1, $arg2) = @_;
	cgen->{code} = [];
	my $reg = cgen->get_reg(32);
	cgen->generate_command('mov', $reg, $arg1);
	cgen->generate_command($type, $reg, $arg2);
	proc->run_code(cgen->{code});
	my $res = proc->get_val($reg);
	my $code_txt = cgen->get_code_txt('hex');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt будут установлены флаги:
QUESTION
;
	my $flags = proc->{eflags}->get_set_flags();
	$self->variants(@{$flags->{flags}});
    $self->{correct} = $flags->{set};
}

1;
