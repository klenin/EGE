# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Asm::Register;

use strict;
use warnings;

use EGE::Bits;
use EGE::Asm::Eflags;
use EGE::Random;


sub new {
	my ($class, %init) = @_;
    my $self = {
		id_from => undef,
		id_to => undef,
		bits => EGE::Bits->new->set_size(32)
	};
   bless $self, ref $class || $class;
   $self;
}

sub set_indexes {
	my ($self, $_) = @_;
	($self->{id_from}, $self->{id_to}) = m/^(a|b|c|d)l$/ ? (24, 32) :
	m/^(a|b|c|d)h$/ ? (16, 24) :
	m/^(a|b|c|d)x$/ ? (16, 32) :
	m/^e(a|b|c|d)x|e(s|b)p$/ ? (0, 32) : 
	(0, 0);
	$self;
}

sub get_value {
	my ($self, $reg, $flip) = @_;
	$self->set_indexes($reg) if ($reg);
	my $len = $self->{id_to} - $self->{id_from};
	my $tmp = EGE::Bits->new->set_size($len);
	for (0 .. $len - 1) {
		$tmp->{v}[$_] = $self->{bits}->{v}[$self->{id_from}+$_];
	}
	if ($flip) {
		my $id = rnd->in_range(0, $len - 1);
		$tmp->{v}[$id] ^= 1;
	}
	$tmp->get_dec();
}

sub set_ZSPF {
	my ($self, $eflags) = @_;
	$eflags->{ZF} = $self->get_value() == 0;
	$eflags->{SF} = $self->{bits}->{v}[$self->{id_from}];
	my $num1 = 0;
	for (24 .. 31) {
		$num1++ if ($self->{bits}->{v}[$_]);
	}
	$eflags->{PF} = !($num1 % 2);
	$self;
}

sub mov {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg) if ($reg);
	$val = 2**($self->{id_to} - $self->{id_from}) + $val if ($val < 0);
	my $tmp = EGE::Bits->new->set_size($self->{id_to} - $self->{id_from});
	$tmp->set_dec($val);
	for (0 .. $self->{id_to} - $self->{id_from} - 1) {
		$self->{bits}->{v}[$self->{id_from}+$_] = $tmp->{v}[$_];
	}
	$self;
}

sub movzx {
	my ($self, $eflags, $reg, $val) = @_;
	$val = 2**(($self->{id_to} - $self->{id_from})/2) + $val if ($val < 0);
	$self->mov($eflags, $reg, $val);
}

sub movsx {
	my ($self, $eflags, $reg, $val) = @_;
	$val = 2**(($self->{id_to} - $self->{id_from})/2) + $val if ($val < 0);
	$self->mov($eflags, $reg, $val);
	my $mid = ($self->{id_from} + $self->{id_to}) / 2;
	my $s = $self->{bits}->{v}[$mid];
	$self->{bits}->{v}[$_] = $s for ($self->{id_from} .. $mid-1);
	$self;
}

sub add {
	my ($self, $eflags, $reg, $val, $cf) = @_;
	$self->set_indexes($reg);
	my $a = 2**($self->{id_to} - $self->{id_from});
	$val = $a + $val if ($val < 0);
	my $regs = $self->{bits}->{v}[$self->{id_from}];
	my $vals = 0;
	$vals = 1 if ($val >= $a/2);
	my $newval = $self->get_value() + $val;
	$newval++ if ($cf && $eflags->{CF});
	$eflags->{CF} = 0;
	$eflags->{CF} = 1, $newval %= $a if ($newval >= $a);
	$self->mov($eflags, '', $newval);
	$eflags->{OF} = 0;
	my $ress = $self->{bits}->{v}[$self->{id_from}];
	$eflags->{OF} = 1 if ($regs == $vals && $regs != $ress);
	$self->set_ZSPF($eflags);
	$self;
}

sub adc {
	my ($self, $eflags, $reg, $val) = @_;
	$self->add($eflags, $reg, $val, 1);
}

sub sub {
	my ($self, $eflags, $reg, $val, $cf) = @_;
	$self->set_indexes($reg) if ($reg);
	my $oldcf = $eflags->{CF};
	my $a = 2**($self->{id_to} - $self->{id_from});
	$val = $a + $val if ($val < 0);
	my $regval = $self->get_value();
	$eflags->{CF} = 0;
	$eflags->{CF} = 1 if ($regval < $val || $regval < $val+1 && $cf && $oldcf);
	$regval = $regval - $a if ($regval >= $a/2);
	$val = $val - $a if ($val >= $a/2);
	my $newval = $regval - $val;
	$newval-- if ($cf && $oldcf);
	$eflags->{OF} = 0;
	$eflags->{OF} = 1 if ($newval >= $a/2 || $newval < -$a/2);
	$newval %= $a;
	$self->mov($eflags, '', $newval);
	$self->set_ZSPF($eflags);
	$self;
}

sub sbb {
	my ($self, $eflags, $reg, $val) = @_;
	$self->sub($eflags, $reg, $val, 1);
}

sub neg {
	my ($self, $eflags, $reg) = @_;
	my $val = $self->get_value($reg);
	$self->mov($eflags, '', 0);
	$self->sub($eflags, '', $val);
	$self;
}

sub and {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg) if ($reg);
	$val = 2**($self->{id_to} - $self->{id_from}) + $val if ($val < 0);
	$self->{bits}->logic_op('and', $val, $self->{id_from}, $self->{id_to});
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$eflags->{CF} = 0;
	$self;
}

sub or {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	$val = 2**($self->{id_to} - $self->{id_from}) + $val if ($val < 0);
	$self->{bits}->logic_op('or', $val, $self->{id_from}, $self->{id_to});
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$eflags->{CF} = 0;
	$self;
}

sub xor {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	$val = 2**($self->{id_to} - $self->{id_from}) + $val if ($val < 0);
	$self->{bits}->logic_op('xor', $val, $self->{id_from}, $self->{id_to});
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$eflags->{CF} = 0;
	$self;
}

sub test {
	my ($self, $eflags, $reg, $val) = @_;
	my $oldval = $self->get_value($reg);
	$self->and($eflags, '', $val);
	$self->mov($eflags, '', $oldval);	
	$self;
}

sub not {
	my ($self, $eflags, $reg) = @_;
	$self->set_indexes($reg);
	$self->{bits}->invert($self->{id_from}, $self->{id_to});
	$self;
}

sub shl {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg) if ($reg);
	my $v = $self->{bits}->{v};
	$eflags->{CF} = $v->[$self->{id_from}+$val-1];
	my $j = $self->{id_from};
	my $len = $self->{id_to} - $self->{id_from};
    $v->[$j++] = $val < $len ? $v->[$self->{id_from}+$val++] : 0 while $j < $self->{id_from} + $len;
	$self->set_ZSPF($eflags) if ($reg);
	$eflags->{OF} = 0 if ($reg);
	$self;
}

sub sal {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	$eflags->{OF} = $self->{bits}->{v}[$self->{id_from}+$val-1] != $self->{bits}->{v}[$self->{id_from}+$val];
	$self->shl($eflags, '', $val);
	$self->set_ZSPF($eflags);
	$self;
}

sub shr {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg) if ($reg);
	my $v = $self->{bits}->{v};
	$eflags->{CF} = $v->[$self->{id_to}-$val];
	my $j = $self->{id_to};
    my $i = $self->{id_to} - $val;
    $v->[--$j] = $i ? $v->[--$i] : 0 while $j > $self->{id_from};
	$self->set_ZSPF($eflags) if ($reg);
	$eflags->{OF} = 0 if ($reg);
	$self;
}

sub sar {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	my $sgn = $self->{bits}->{v}[$self->{id_from}];
	$self->shr($eflags, '', $val);
	$self->{bits}->{v}[$self->{id_from}+$_] = $sgn for (0..$val-1);
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$self;
}

sub rol {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	$val %= $self->{id_to} - $self->{id_from};
	for (1..$val) {
		$self->shl($eflags, '', 1);
		$self->{bits}->{v}[$self->{id_to} - 1] = $eflags->{CF};
	}
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$self;
}

sub rcl {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	$val %= $self->{id_to} - $self->{id_from};
	for (1..$val) {
		my $prevc = $eflags->{CF};
		$self->shl($eflags, '', 1);
		$self->{bits}->{v}[$self->{id_to} - 1] = $prevc;
	}
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$self;
}

sub ror {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	$val %= $self->{id_to} - $self->{id_from};
	for (1..$val) {
		$self->shr($eflags, '', 1);
		$self->{bits}->{v}[$self->{id_from}] = $eflags->{CF};
	}
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$self;
}

sub rcr {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	$val %= $self->{id_to} - $self->{id_from};
	for (1..$val) {
		my $prevc = $eflags->{CF};
		$self->shr($eflags, '', 1);
		$self->{bits}->{v}[$self->{id_from}] = $prevc;
	}
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$self;
}

1;
