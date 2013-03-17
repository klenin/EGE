# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Asm::AsmCodeGenerate;

use strict;
use warnings;

use EGE::Random;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(cgen);

my $cgen;

sub cgen {
    $cgen ||= EGE::Asm::AsmCodeGenerate->new;
}

sub new {
    my $self = { code => [] };
    bless $self, shift;
    $self;
}

sub generate_command {
	my ($self, $type, $reg, $lo, $hi) = @_;
	my ($cmd, $arg);
	if ($type eq 'mov') {
		$lo = 1, $hi = 255 if (!defined $lo);
		$cmd = 'mov';
	}
	if ($type eq 'add') {
		$lo = 65, $hi = 255 if (!defined $lo);
		$cmd = rnd->pick('add', 'sub', 'adc', 'sbb', 'neg');
	}
	if ($type eq 'logic') {
		$lo = 1, $hi = 255 if (!defined $lo);
		$cmd = rnd->pick('and', 'or', 'xor', 'test', 'not');
	}
	if ($type eq 'shift') {
		$lo = 1, $hi = 4 if (!defined $lo);
		$cmd = rnd->pick('shl', 'shr', 'sal', 'sar', 'rol', 'ror', 'rcl', 'rcr');
	}
	if ($type eq 'convert') {
		$lo = 0, $hi = 255 if (!defined $lo);
		$cmd = rnd->pick('movzx', 'movsx');
	}
	$self->add_command(rnd->pick('stc', 'clc')) if $self->use_cf($cmd);
	$arg = $self->single_arg($cmd) ? '' : defined $hi ? rnd->in_range($lo, $hi) : $lo;
	$self->add_command($cmd, $reg, $arg);
}

sub add_command {
	my $self = shift;
	push $self->{code}, [ @_ ];
}

sub get_code_txt {
	my ($self, $type) = @_;
	my $res = '<br></br><code>';
	for my $str (@{$self->{code}}) {
		my $i=0;
		for (grep {!($_ eq '')} @$str) {
			$res .= $i == 0 ? '' : $i == 1 ? ' ' : ', ';
			$res .= (m/^-?(\d*)$/ && $type eq 'hex') ? sprintf '%08Xh', $_ : sprintf '%s', $_;
			$i++;
		}
		$res .= '<br></br>';
	}
	$res .= '</code>';
	$res;
}

sub get_reg {
	my ($self, $size) = @_;
	sprintf { 32 => 'e%sx', 16 => '%sx', 8 => '%s'.rnd->pick('h', 'l') }->{$size}, rnd->pick('a'..'d');
}

sub single_arg {
	my ($self, $cmd) = @_;
	my %hash = (not => 1, neg => 1);
	$hash{$cmd};
}

sub use_cf {
	my ($self, $cmd) = @_;
	my %hash = (adc => 1, sbb => 1, rcl => 1, rcr => 1);
	$hash{$cmd};
}


1;
