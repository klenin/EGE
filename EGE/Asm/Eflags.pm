# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Asm::Eflags;

use strict;
use warnings;

my $flags = ['ZF', 'SF', 'PF', 'CF', 'OF'];

sub new {
	my ($class, %init) = @_;
	my $self = {};
	bless $self, ref $class || $class;
	$self;
}


sub init {
	my $self = shift;
	$self->{$_} = 0 for (@$flags);
}

sub valid_jump {
	my ($self, $cmd) = @_;
	return
	$cmd eq 'jc' || $cmd eq 'jb' || $cmd eq 'jnae' ? $self->{CF} :
	$cmd eq 'jp' ? $self->{PF} :
	$cmd eq 'jz' || $cmd eq 'je' ? $self->{ZF} :
	$cmd eq 'js' ? $self->{SF} :
	$cmd eq 'jo' ? $self->{OF} :
	$cmd eq 'jnc' || $cmd eq 'jae' || $cmd eq 'jnb' ? !$self->{CF} :
	$cmd eq 'jnp' ? !$self->{PF} :
	$cmd eq 'jnz' || $cmd eq 'jne' ? !$self->{ZF} :
	$cmd eq 'jns' ? !$self->{SF} :
	$cmd eq 'jno' ? !$self->{OF} :
	$cmd eq 'jl' || $cmd eq 'jnge' ? $self->{SF} != $self->{OF} :
	$cmd eq 'jle' || $cmd eq 'jng' ? $self->{SF} != $self->{OF} || $self->{ZF} :
	$cmd eq 'jg' || $cmd eq 'jnle' ? $self->{SF} == $self->{OF} && !$self->{ZF} :
	$cmd eq 'jge' || $cmd eq 'jnl' ? $self->{SF} == $self->{OF} :
	$cmd eq 'jbe' || $cmd eq 'jna' ? $self->{CF} || $self->{ZF} :
	$cmd eq 'ja' || $cmd eq 'jnbe' ? !$self->{CF} && !$self->{ZF} :
	$cmd eq 'jmp' ? 1 : '';
}

1;
