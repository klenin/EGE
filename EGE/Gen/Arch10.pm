# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch10;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::AsmCodeGenerate;

sub jcc_check_flags {
    my $self = shift;
    my $jmp = 'j' . rnd->pick('', 'n') . rnd->pick(qw(e g l ge le a b ae be));
    my $f = EGE::Asm::Eflags->new;
    my @flags = $f->flags;
    $self->variants(@flags);
    $self->{correct} = [ map $f->jump_checks_flag($jmp, $_), @flags ];
    $self->{text} = "Команда $jmp проверяет флаги:";
}

sub cmovcc {
	my $self = shift;
	cgen->{code} = [];
	my ($reg1, $reg2) = cgen->get_regs(32, 32);
	my $cc = {1 => 'n', 0 => ''}->{rnd->pick(0,1)}.rnd->pick(qw(c p z o s e g l ge le a b ae be));
	my $label = 'L';
	cgen->add_command('j'.$cc, $label);
	cgen->add_command('mov', $reg1, $reg2);
	cgen->add_command($label.':');
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
		push @variants, $cc =~ /^n\w+$/ ? substr($cc, 1) : 'n'.$cc;
		$self->{correct} = [1, 0, 0, 0];
	}
	push @variants, $cc;
	while ($#variants < 3) {
		my $v = {1 => 'n', 0 => ''}->{rnd->pick(0,1)}.rnd->pick(qw(c p z o s e g l ge le a b ae be));
		push @variants, $v if !(grep {$_ eq $v} @variants);
	}
	$self->formated_variants("cmov%s $reg1, $reg2", @variants);
}

1;
