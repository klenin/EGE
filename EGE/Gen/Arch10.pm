# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch10;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub jcc_check_flags {
	my $self = shift;
	my $jmp = 'j'.{1 => 'n', 0 => ''}->{rnd->pick(0,1)}.rnd->pick(qw(e g l ge le a b ae be));
	$self->{text} = <<QUESTION
Команда $jmp проверяет флаги:
QUESTION
;
	$self->variants(qw(CF OF SF ZF PF));
	$self->{correct} = $jmp eq 'je' || $jmp eq 'jne' ? [0, 0, 0, 1, 0] :
		$jmp eq 'jl' || $jmp eq 'jnge' || $jmp eq 'jge' || $jmp eq 'jnl' ? [0, 1, 1, 0, 0] :
		$jmp eq 'jle' || $jmp eq 'jng' || $jmp eq 'jg' || $jmp eq 'jnle' ? [0, 1, 1, 1, 0] :
		$jmp eq 'jb' || $jmp eq 'jnae' || $jmp eq 'jae' || $jmp eq 'jnb' ? [1, 0, 0, 0, 0] :
		$jmp eq 'jbe' || $jmp eq 'jna' || $jmp eq 'ja' || $jmp eq 'jnbe' ? [1, 0, 0, 1, 0] : '';
}

sub cmovcc {
	my $self = shift;
	cgen->{code} = [];
	my ($reg1, $reg2) = (cgen->get_reg(32), cgen->get_reg(32));
	$reg2 = cgen->get_reg(32) while $reg2 eq $reg1;
	my $cc = {1 => 'n', 0 => ''}->{rnd->pick(0,1)}.rnd->pick(qw(c p z o s e g l ge le a b ae be));
	my $l = 'L';
	cgen->add_command('j'.$cc, $l);
	cgen->add_command('mov', $reg1, $reg2);
	cgen->add_command($l.':');
	my $code_txt = cgen->get_code_txt('%s');
	$self->{text} = <<QUESTION
Последовательность команд $code_txt эквивалентна команде:
QUESTION
;
	my @variants;
	if ($cc eq 'c' || $cc eq 'nae' || $cc eq 'b') {
		@variants = ('nc', 'ae', 'nb');
		$self->{correct} = [1, 1, 1, 0];
	}
	elsif ($cc eq 'nc' || $cc eq 'nb' || $cc eq 'ae') {
		@variants = ('c', 'b', 'nae');
		$self->{correct} = [1, 1, 1, 0];
	}
	elsif ($cc eq 'z' || $cc eq 'e') {
		@variants = ('ne', 'nz');
		$self->{correct} = [1, 1, 0, 0];
	}
	elsif ($cc eq 'nz' || $cc eq 'ne') {
		@variants = ('e', 'z');
		$self->{correct} = [1, 1, 0, 0];
	}
	else {
		$_ = $cc;
		push @variants, m/^n\w+$/ ? substr($cc, 1) : 'n'.$cc;
		$self->{correct} = [1, 0, 0, 0];
	}
	push @variants, $cc;
	while ($#variants < 3) {
		my $v = {1 => 'n', 0 => ''}->{rnd->pick(0,1)}.rnd->pick(qw(c p z o s e g l ge le a b ae be));
		push @variants, $v if !(grep {$_ eq $v} @variants);
	}
	$self->variants(grep { $_ = "cmov$_ $reg1, $reg2" } @variants);
}

1;
