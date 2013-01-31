# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Asm::Eflags;

use strict;
use warnings;


sub new {
	my ($class, %init) = @_;
	my $self = {};
	bless $self, ref $class || $class;
	$self;
}


sub init {
	my $self = shift;
	$self->{ZF} = 0;
	$self->{SF} = 0;
	$self->{PF} = 0;
	$self->{CF} = 0;
	$self->{OF} = 0;
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
	'';
}

sub get_set_flags {
	my $self = shift;
	my $flags = ['ZF', 'SF', 'PF', 'CF', 'OF'];
	my $arr = [];
	push($arr, 0) if ($self->{ZF});
	push($arr, 1) if ($self->{SF});
	push($arr, 2) if ($self->{PF});
	push($arr, 3) if ($self->{CF});
	push($arr, 4) if ($self->{OF});
	{'flags', $flags, 'set', $arr};
}

1;
