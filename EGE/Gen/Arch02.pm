# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch02;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub flags_value_add {
	my $self = shift;
	$self->flags_value('add');
}

sub flags_value_logic {
	my $self = shift;
	$self->flags_value('logic');
}

sub flags_value_shift {
	my $self = shift;
	$self->flags_value('shift');
}

sub flags_value {
	my ($self, $type) = @_;
	cgen->{code} = [];
	my $reg = cgen->get_reg(8);
	cgen->generate_command('mov', $reg);
	cgen->generate_command($type, $reg);
	proc->run_code(cgen->{code});
	my $code_txt = cgen->get_code_txt('%s');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt будут установлены флаги:
QUESTION
;
	my $flags = proc->{eflags}->get_set_flags();
	$self->variants(@{$flags->{flags}});
    $self->{correct} = $flags->{set};
	$self->flags_value($type) if !(grep $_, @{$flags->{set}});
}

1;
