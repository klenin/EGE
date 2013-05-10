# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch07;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub loop_number {
	my $self = shift;
	cgen->{code} = [];
	my ($reg, $reg2) = cgen->get_regs(8, 8);
	my $arg = rnd->pick(1..126, 128..254);
	cgen->add_command('mov', $reg, $arg);
	my $l = 'L';
	cgen->add_command($l.':');
	cgen->add_command('add', $reg, 1);
	my $jmp = 'j'.rnd->pick(qw(p o s nc np nz no ns));
	$jmp = 'jns' if ($jmp eq 'js' && $arg < 128);
	$jmp = 'js' if ($jmp eq 'jns' && $arg >= 128);
	cgen->add_command($jmp, $l);
	my $code_txt = cgen->get_code_txt('%s');
	$self->{text} = <<QUESTION
При выполнении кода $code_txt в команда <code>add $reg, 1</code> будет выполнена раз:
QUESTION
;
	if ($jmp eq 'jp' || $jmp eq 'jnp') {
		$self->variants(1, 2, 3, "бесконечное число (программа зациклится)");
		$_ = $reg;
		if (m/^(a|b|c|d)h$/) {
			$self->{correct} = $jmp eq 'jp' ? 3 : 0;
		}
		else {
			cgen->add_command('add', $reg2, 1);
			cgen->swap_commands(3,4);
			cgen->swap_commands(2,3);
			proc->run_code(cgen->{code});
			$self->{correct} = proc->get_val($reg2) - 1;
		}
	}
	elsif ($jmp eq 'jo') {
		$self->variants(1, 256 - $arg, (128 - $arg)%256, "бесконечное число (программа зациклится)");
		$self->{correct} = 0;
	}
	else {
		my $res = $jmp eq 'jnc' || $jmp eq 'jnz' || $jmp eq 'js' ? 256 - $arg :
			$jmp eq 'jno' && $arg < 128 || $jmp eq 'jns' ? 128 - $arg :
			$jmp eq 'jno' && $arg >= 128 ? 256 - $arg + 128 : '';
		my $res1 = $res == 2 ? 3 : rnd->pick($res+1, $res-1);
		$self->variants($res, $res1, 1, "бесконечное число (программа зациклится)");
		$self->{correct} = 0;
	}
}

1;
