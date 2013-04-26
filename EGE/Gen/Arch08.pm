# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch08;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub choose_jump {
	my $self = shift;
	cgen->{code} = [];
	my $reg = cgen->get_reg(8);
	cgen->generate_command('mov', $reg);
	rnd->pick(0,1) ? cgen->add_command('sub', $reg, rnd->in_range(1, 255)) : cgen->add_command('neg', $reg);
	my $l = 'L';
	my @jumps = rnd->pick_n(2, qw(jc jz jo js jnc jnz jno jns));
	push @jumps, rnd->pick_n(2, qw(je jne jl jnge jle jng jg jnle jge jnl jb jnae jbe jna ja jnbe jae jnb));
	cgen->add_command($jumps[0], $l);
	cgen->add_command('add', $reg, 1);
	cgen->add_command($l.':');
	proc->run_code(cgen->{code});
	my $res = proc->get_val($reg);
	my @correct = (1);
	for my $i (1..$#jumps) {
		cgen->{code}->[2]->[0] = $jumps[$i];
		proc->run_code(cgen->{code});
		$correct[$i] = proc->get_val($reg) == $res ? 1 : 0;
	}
	cgen->{code}->[2]->[0] = "jcc";
	my $code_txt = cgen->get_code_txt('%s');
	$self->{text} = <<QUESTION
В результате выполнения кода $code_txt в $reg будет содержаться значение $res. jcc можно заменить на:
QUESTION
;
	my $flags = proc->{eflags}->get_set_flags();
	$self->variants(@jumps);
    $self->{correct} = \@correct;
}

1;
