# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch06;
use base 'EGE::GenBase::Match';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub match_values {
	my $self = shift;
	my ($a, $b) = rnd->pick_n(2, ('a', 'b', 'c', 'd'));
	my @regs8 = ($a.'l', $a.'h', $b.'l', $b.'h');
	my @regs16 = ($a.'x', $b.'x');
	cgen->{code} = [];
	map cgen->add_command('mov', $_, $self->get_8b_val() * 256 + $self->get_8b_val()), @regs16;
	cgen->add_command(rnd->pick('shl', 'shr', 'sal', 'sar', 'rol', 'ror'), rnd->pick(@regs8), 4);
	cgen->add_command(rnd->pick('and', 'or', 'xor'), rnd->pick_n(2, @regs8));
	cgen->add_command(rnd->pick('add', 'sub', 'adc', 'sbb'), rnd->pick_n(2, @regs16));
	proc->run_code(cgen->{code});
	my @vals = map proc->get_val($_), @regs8;
	my $code_txt = cgen->get_code_txt('%04Xh');
	$self->{text} = <<QUESTION
Процессором был выполнен следующий код: $code_txt Установить соответствие между регистрами и полученными в них значениями
QUESTION
;
	$self->{left_column} = \@regs8;
	$self->variants(map {sprintf '%02Xh', $_} @vals);
    $self->{correct} = [0,1,2,3];
	my $unique_vals = 1;
	for my $i (0..3) {
		$unique_vals = '' if ((grep $_ == $vals[$i], @vals) > 1);
	}
	$self->match_values if (!$unique_vals);
}

sub get_8b_val {
	my $self = shift;
	rnd->pick(0,1) ? rnd->pick(0,15) * 16 + rnd->in_range(1,14) : rnd->in_range(1,14) * 16 + rnd->pick(0,15);
}

1;
