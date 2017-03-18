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
        bits => EGE::Bits->new->set_size(32),
        %init,
    };
    bless $self, ref $class || $class;
    $self;
}

my %reg_indexes = (
	(map { $_ . 'l' => [ 24, 32 ] } 'a'..'d'),
    (map { $_ . 'h' => [ 16, 24 ] } 'a'..'d'),
    (map { $_ . 'x' => [ 16, 32 ] } 'a'..'d'),
    (map { $_ => [ 0, 32 ] } qw(esi edi ebp esp), map "e${_}x", 'a'..'d'),
	(map { $_ => [ 0, 16 ] } qw(si di bp sp)),
);

sub set_indexes {
    my ($self, $reg) = @_;
    ($self->{id_from}, $self->{id_to}) = @{$reg_indexes{$reg}};
    $self;
}

sub get_value {
    my ($self, $reg, $flip) = @_;
    $self->set_indexes($reg) if $reg;
    my $len = $self->{id_to} - $self->{id_from};
    my $tmp = EGE::Bits->new->
        set_bin_array([ @{$self->{bits}->{v}}[$self->{id_from} .. $self->{id_to} - 1] ], 1);
    $tmp->{v}[rnd->in_range(0, $len - 1)] ^= 1 if $flip;
    $tmp->get_dec;
}

sub set_ZSPF {
    my ($self, $eflags) = @_;
    $eflags->{ZF} = $self->get_value() ? 0 : 1;
    $eflags->{SF} = $self->{bits}->{v}[$self->{id_from}];
    $eflags->{PF} = 1 - scalar(grep $self->{bits}->{v}[$_], $self->{id_to} - 8 .. $self->{id_to} - 1) % 2;
    $self;
}

sub mov_value {
    my ($self, $val) = @_;
    my $len = $self->{id_to} - $self->{id_from};
    $val += 2 ** $len if $val < 0;
    my $tmp = EGE::Bits->new->set_size($len)->set_dec($val);
    splice @{$self->{bits}->{v}}, $self->{id_from}, $len, @{$tmp->{v}};
    $self;
}

sub mov {
    my ($self, $eflags, $reg, $val) = @_;
    $self->set_indexes($reg) if $reg;
    $self->mov_value($val);
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
    my ($self, $eflags, $reg, $val, $use_cf) = @_;
    $self->set_indexes($reg) if $reg;
    my $oldcf = $use_cf ? $eflags->{CF} : 0;
    my $a = 2 ** ($self->{id_to} - $self->{id_from});
    $val += $a if $val < 0;
    my $regval = $self->get_value();
    $eflags->{CF} = $regval < $val + $oldcf ? 1 : 0;
    $regval -= $a if $regval >= $a / 2;
    $val -= $a if $val >= $a / 2;
    my $newval = $regval - $val - $oldcf;
    $eflags->{OF} = $newval >= $a / 2 || $newval < -$a / 2 ? 1 : 0;
    $newval %= $a;
    $self->mov_value($newval)->set_ZSPF($eflags);
}

sub sbb {
	my ($self, $eflags, $reg, $val) = @_;
	$self->sub($eflags, $reg, $val, 1);
}

sub cmp {
    my ($self, $eflags, $reg, $val) = @_;
    my $tmp = $self->new;
    $tmp->{bits}->copy($self->{bits});
    $tmp->sub($eflags, $reg, $val);
}

sub neg {
	my ($self, $eflags, $reg) = @_;
	my $val = $self->get_value($reg);
	$self->mov($eflags, '', 0);
	$self->sub($eflags, '', $val);
	$self;
}

# TODO: Это заглушка только для использования в Arch13.
sub imul {
    my ($self, $eflags, $reg, $val) = @_;
    $self->set_indexes($reg);
    $self->mov_value($self->get_value * $val)->set_ZSPF($eflags);
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
	$self->{bits}->logic_op('not', '', $self->{id_from}, $self->{id_to});
	$self;
}

sub shl {
    my ($self, $eflags, $reg, $val) = @_;
    $val >= 0 or die "Bad shift count: $val";
    $val %= 32 or return $self;
    $self->set_indexes($reg) if $reg;
    my $last = $self->{id_from} + $val;
    $eflags->{CF} = $last > $self->{id_to} ? 0 : $self->{bits}->{v}->[$last - 1];
    $self->{bits}->shift_(-$val, $self->{id_from}, $self->{id_to});
    $eflags->{OF} = $self->{bits}->{v}->[$self->{id_from}] != $eflags->{CF} ? 1 : 0
        if $reg && $val == 1;
    $self->set_ZSPF($eflags) if $reg;
}

sub sal { goto &shl; }

sub shr {
    my ($self, $eflags, $reg, $val) = @_;
    $val >= 0 or die "Bad shift count: $val";
    $val %= 32 or return $self;
    $self->set_indexes($reg) if $reg;
    my $last = $self->{id_to} - $val;
    $eflags->{CF} = $last < $self->{id_from} ? 0 : $self->{bits}->{v}->[$last];
    $eflags->{OF} = $self->{bits}->{v}->[$self->{id_from}] if $val == 1;
    $self->{bits}->shift_($val, $self->{id_from}, $self->{id_to});
    $self->set_ZSPF($eflags);
}

sub sar {
    my ($self, $eflags, $reg, $val) = @_;
    $reg or die;
    $val >= 0 or die "Bad shift count: $val";
    $val %= 32 or return $self;
    $self->set_indexes($reg);
    my $sgn = $self->{bits}->{v}[$self->{id_from}];
    my $last = $self->{id_to} - $val;
    $eflags->{CF} = $last < $self->{id_from} ? 0 : $self->{bits}->{v}->[$last];
    $eflags->{OF} = 0 if $val == 1;
    $self->{bits}->shift_($val, $self->{id_from}, $self->{id_to}, $sgn);
    $self->set_ZSPF($eflags);
}

sub rol {
	my ($self, $eflags, $reg, $val) = @_;
	$self->rotate_shift($eflags, $reg, $val, sub {
		$self->shl($eflags, '', 1);
		$self->{bits}->{v}[$self->{id_to} - 1] = $eflags->{CF};
	});
	$self;
}

sub rcl {
	my ($self, $eflags, $reg, $val) = @_;
	$self->rotate_shift($eflags, $reg, $val, sub {
		my $prevc = $eflags->{CF};
		$self->shl($eflags, '', 1);
		$self->{bits}->{v}[$self->{id_to} - 1] = $prevc;
	});
	$self;
}

sub ror {
	my ($self, $eflags, $reg, $val) = @_;
	$self->rotate_shift($eflags, $reg, $val, sub {
		$self->shr($eflags, '', 1);
		$self->{bits}->{v}[$self->{id_from}] = $eflags->{CF};
	});
	$self;
}

sub rcr {
	my ($self, $eflags, $reg, $val) = @_;
	$self->rotate_shift($eflags, $reg, $val, sub {
		my $prevc = $eflags->{CF};
		$self->shr($eflags, '', 1);
		$self->{bits}->{v}[$self->{id_from}] = $prevc;
	});
	$self;
}

sub rotate_shift {
	my ($self, $eflags, $reg, $val, $sub) = @_;
	$self->set_indexes($reg);
	$val %= $self->{id_to} - $self->{id_from};
	for (1..$val) {
		$sub->();
	}
	$self->set_ZSPF($eflags);
	$eflags->{OF} = 0;
	$self;
}

sub push {
	my ($self, $eflags, $reg, $stack) = @_;
	unshift @{$stack}, $self->get_value($reg);
	$self;
}

sub pop {
	my ($self, $eflags, $reg, $stack) = @_;
	$self->mov($eflags, $reg, shift @{$stack});
	$self;
}

sub bsf {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	my $tmp = EGE::Bits->new->set_size(32)->set_dec($val);
	my $value = $tmp->frscan('f');
	$eflags->{ZF} = 1;
	if ($value == -1) {
		$eflags->{ZF} = 0;
		$value = 0;
	} 
	$self->{bits} = EGE::Bits->new->set_size(16)->set_dec($value);
	$self;
}

sub bsr {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	my $tmp = EGE::Bits->new->set_size(32)->set_dec($val);
	my $value = $tmp->frscan('r');
	$eflags->{ZF} = 1;
	if ($value == -1) {
		$eflags->{ZF} = 0;
		$value = 0;
	} 
	$self->{bits} = EGE::Bits->new->set_size(16)->set_dec($value);
	$self;
}

sub bswap {
	my ($self, $eflags, $reg, $val) = @_;
	$self->set_indexes($reg);
	$self->{bits}->bswap;
	$self;
}

1;
