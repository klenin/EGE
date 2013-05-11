# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch03;
use base 'EGE::GenBase::MultipleChoiceFixedVariants';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub choose_commands {
	my $self = shift;
	cgen->{code} = [];
	my $reg = cgen->get_reg(8);
	my $jmp = rnd->pick('jnc', 'jns', 'js');
	my $arg = { jnc => rnd->pick(0..41)*6 + 3, jns => rnd->pick(0..20)*6 + 1, js => rnd->pick(21..41)*6 + 3 }->{$jmp};
	my $l = 'L';
	my $val_add = rnd->in_range(1, 3);
	cgen->add_command('mov', $reg, $arg);
	cgen->add_command($l.':');
	cgen->add_command('add', $reg, $val_add);
	cgen->add_command($jmp, $l);
	$self->variants(map { $_ = "<code>$_</code>" } ("mov $reg, $arg", "$l:", "add $reg, 1", "add $reg, 2", "$jmp $l"));
	$self->{correct} = {1 => [1, 1, 1, 0, 1], 2 => [1, 1, 0, 1, 1], 3 => [1, 1, 1, 1, 1]}->{$val_add};
	proc->run_code(cgen->{code});
	my $res = proc->get_val($reg);
	$self->{text} = <<QUESTION
Отметьте команды так, чтобы после выполнения полученного кода в регистре $reg содержалось значение $res
QUESTION
;
}

1;
