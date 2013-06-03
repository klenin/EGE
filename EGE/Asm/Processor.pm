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
my $registers = ['eax', 'ebx', 'ecx', 'edx', 'esp', 'ebp'];

sub proc {
    $proc ||= EGE::Asm::Processor->new;
}

sub new {
    my $self = {
		eflags => EGE::Asm::Eflags->new
	};
	$self->{$_} = EGE::Asm::Register->new for (@$registers);
    bless $self, shift;
    $self;
}

sub init {
	my $self = shift;
	$self->{$_}->mov($self->{eflags}, $_, 0) for (@$registers);
	$self->{eflags}->init;
	$self->{stack} = [];
}

sub get_register {
	my ($self, $reg) = @_;
	return $self if (!defined $reg);
	return ($reg =~ /^(e?)([a-d])(l|h|x)$/) ? $self->{"e$2x"} : $self->{$reg};
}

sub get_val {
	my ($self, $arg) = @_;
	$arg //= '';
	$arg =~ /^-?(\d*)$/ ? $arg : $self->get_register($arg)->get_value($arg);
}

sub get_wrong_val {
	my ($self, $reg) = @_;
	$self->get_register($reg)->get_value($reg, 1);
}

sub run_cmd {
	my ($self, $cmd, $reg, $arg) = @_;
	$arg = 'cl' if ($self->is_shift($cmd) && !defined $arg);
	my $val = $self->is_stack_command($cmd) ? $self->{stack} : $self->get_val($arg);
	no strict 'refs';
	$self->get_register($reg)->$cmd($self->{eflags}, $reg, $val);
	$self;
}

sub run_code {
	my ($self, $code) = @_;
	$self->init();
	my %labels;
	for my $i (0..$#{$code}) {
		my $label = substr($code->[$i]->[0], 0, -1);
		$labels{$label} = $i if ($self->is_label($code->[$i]->[0]));
	}
	my $i = -1;
	while ($i < $#{$code}) {
		$i++;
		my $str = $code->[$i];
		next if ($self->is_label($str->[0]));
		my $is_jump = $self->is_jump($str->[0]);
		$i = $labels{$str->[1]} - 1 if ($is_jump && $self->{eflags}->valid_jump($str->[0]));
		next if ($is_jump);
		$self->run_cmd(@$str);
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
	{ shl => 1, shr => 1, sal => 1, sar => 1, rol => 1, ror => 1, rcl => 1, rcr => 1 }->{$cmd};
}

sub is_label {
	my ($self, $l) = @_;
	$l =~ /^(\w+):$/;
}

sub is_jump {
	my ($self, $cmd) = @_;
	{ jc => 1, jp => 1, jz => 1, jo => 1, js => 1, jnc => 1, jnp => 1, jnz => 1, jno => 1, jns => 1,
	je => 1, jne => 1, jl => 1, jnge => 1, jle => 1, jng => 1, jg => 1, jnle => 1, jge => 1, jnl => 1,
	jb => 1, jnae => 1, jbe => 1, jna => 1, ja => 1, jnbe => 1, jae => 1, jnb => 1, jmp => 1 }->{$cmd};
}

sub is_stack_command {
	my ($self, $cmd) = @_;
	{ push => 1, pop => 1 }->{$cmd};
}

sub print_state {
	my $self = shift;
	print $_." = ".$self->{$_}->get_value($_)."\n" for (@$registers);
	print $_." = ".$self->{eflags}->{$_}."\n" for (keys %{$self->{eflags}});
	print "stack:\n";
	print $_."\n" for (@{$self->{stack}});
	$self;
}

1;
