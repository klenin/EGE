# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Asm::Processor;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(proc);

use EGE::Asm::Register;
use EGE::Asm::Eflags;

my $proc;


sub proc {
    $proc ||= EGE::Asm::Processor->new;
}

sub new {
    my $self = {
		eax => EGE::Asm::Register->new,
		ebx => EGE::Asm::Register->new,
		ecx => EGE::Asm::Register->new,
		edx => EGE::Asm::Register->new,
		esp => EGE::Asm::Register->new,
		ebp => EGE::Asm::Register->new,
		eflags => EGE::Asm::Eflags->new
	};
    bless $self, shift;
    $self;
}

sub init {
	my $self = shift;
	$self->{eax}->mov($self->{eflags}, 'eax', 0);
	$self->{ebx}->mov($self->{eflags}, 'ebx', 0);
	$self->{ecx}->mov($self->{eflags}, 'ecx', 0);
	$self->{edx}->mov($self->{eflags}, 'edx', 0);
	$self->{esp}->mov($self->{eflags}, 'esp', 0);
	$self->{ebp}->mov($self->{eflags}, 'ebp', 0);
	$self->{eflags}->init;
	$self->{stack} = [];
}

sub get_register {
	my ($self, $_) = @_;
	return $self if (!defined $_);
	return $self->{eax} if (m/^al|ah|ax|eax$/);
	return $self->{ebx} if (m/^bl|bh|bx|ebx$/);
	return $self->{ecx} if (m/^cl|ch|cx|ecx$/);
	return $self->{edx} if (m/^dl|dh|dx|edx$/);
	return $self->{ebp} if (m/^ebp$/);
	return $self->{esp} if (m/^esp$/);
}

sub get_val {
	my ($self, $_) = @_;
	$_ = '' if (!defined $_);
	m/^-?(\d*)$/ ? $_ : $self->get_register($_)->get_value($_);
}

sub get_wrong_val {
	my ($self, $reg) = @_;
	$self->get_register($reg)->get_value($reg, 1);
}

sub run_cmd {
	my ($self, $cmd, $reg, $arg) = @_;
	$arg = 'cl' if ($self->is_shift($cmd) && !defined $arg);
	my $val = $self->get_val($arg);
	no strict 'refs';
	$self->get_register($reg)->$cmd($self->{eflags}, $reg, $val);
	$self;
}

sub run_code {
	my ($self, $code) = @_;
	$self->init();
	my %labels = ();
	for my $i (0..$#{$code}) {
		my $label = substr($code->[$i]->[0], 0, -1);
		$labels{$label} = $i if ($self->is_label($code->[$i]->[0]));
	}
	my $i = -1;
	while ($i < $#{$code}) {
		$i++;
		next if ($self->is_label($code->[$i]->[0]));
		my $is_jump = $self->is_jump($code->[$i]->[0]);
		$i = $labels{$code->[$i]->[1]} - 1 if ($is_jump && $self->{eflags}->valid_jump($code->[$i]->[0]));
		next if ($is_jump);
		$self->run_cmd($code->[$i]->[0], $code->[$i]->[1], $code->[$i]->[2]);
	}
	$self;
}

sub stc {
	my $self = shift;
	$self->{eflags}->{CF} = 1;
	$self;
}

sub clc {
	my $self = shift;
	$self->{eflags}->{CF} = 0;
	$self;
}

sub is_shift {
	my ($self, $cmd) = @_;
	my %hash = (shl => 1, shr => 1, sal => 1, sar => 1, rol => 1, ror => 1, rcl => 1, rcr => 1);
	$hash{$cmd};
}

sub is_label {
	my ($self, $_) = @_;
	m/^(\w+):$/;
}

sub is_jump {
	my ($self, $cmd) = @_;
	my %hash = (jc => 1, jp => 1, jz => 1, jo => 1, js => 1, jnc => 1, jnp => 1, jnz => 1, jno => 1, jns => 1,
	je => 1, jne => 1, jl => 1, jnge => 1, jle => 1, jng => 1, jg => 1, jnle => 1, jge => 1, jnl => 1,
	jb => 1, jnae => 1, jbe => 1, jna => 1, ja => 1, jnbe => 1, jae => 1, jnb => 1);
	$hash{$cmd};
}

1;
