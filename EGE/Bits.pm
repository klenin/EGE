package EGE::Bits;

use strict;
use warnings;

sub new {
    my ($class, %init) = @_;
    my $self = { v => [] };
    bless $self, $class;
    $self;
}

sub get_size { scalar @{$_[0]->{v}}; }

sub set_size {
    my ($self, $new_size) = @_;
    $self->{v} = [ (0) x $new_size ];
    $self;
}

sub get_bin { return join '', @{$_[0]->{v}} }

sub set_bin {
    my ($self, $new_bin) = @_;
    if (ref $new_bin eq 'ARRAY') {
        if (my $i = $self->get_size) {
            my $j = @$new_bin;
            $self->{v}->[--$i] = $new_bin->[--$j] while $i;
        }
        else {
            $self->{v} = $new_bin;
        }
    }
    else {
        $self->get_size || $self->set_size(length $new_bin);
        $self->{v}->[$_] = substr($new_bin, $_, 1) == 1 ? 1 : 0
            for 0 .. $self->get_size - 1;
    }
    $self;
}

sub get_oct {
    my ($self) = @_;
    my $v = $self->{v};
    my $r = '0' x (($self->get_size + 2) / 3);
    my $s = 0;
    my $p = 1;
    my $j = length $r;
    for (my $i = $#$v; $i >= 0; --$i) {
        $s += $p * $v->[$i];
        $p <<= 1;
        next if $p < 8;
        substr($r, --$j, 1) = $s;
        $s = 0;
        $p = 1;
    }
    substr($r, --$j, 1) = $s if $j;
    $r;
}

sub set_oct {
    my ($self, $new_oct) = @_;
    $self->get_size || $self->set_size(3 * length $new_oct);
    my $v = $self->{v};
    my $ds = [ [0,0,0], [0,0,1], [0,1,0], [0,1,1], [1,0,0], [1,0,1], [1,1,0], [1,1,1] ];
    my $j = 0;
    for my $i (0 .. length($new_oct) - 1) {
        my $d = $ds->[substr($new_oct, $i, 1)];
        for (@$d) {
            return if $j >= @$v;
            $v->[$j++] = $_;
        }
    }
    $self;
}

sub get_hex {
    my ($self) = @_;
    my $v = $self->{v};
    my $r = '0' x (($self->get_size + 3) / 4);
    my $s = 0;
    my $p = 1;
    my $j = length $r;
    for (my $i = $#$v; $i >= 0; --$i) {
        $s += $p * $v->[$i];
        $p <<= 1;
        next if $p < 16;
        substr($r, --$j, 1) = sprintf '%X', $s;
        $s = 0;
        $p = 1;
    }
    substr($r, --$j, 1) = sprintf '%X', $s if $j;
    $r;
}

sub set_hex {
    my ($self, $new_hex) = @_;
    $self->get_size || $self->set_size(4 * length $new_hex);
    my $v = $self->{v};
    my $ds = [
        [0,0,0,0], [0,0,0,1], [0,0,1,0], [0,0,1,1], [0,1,0,0], [0,1,0,1], [0,1,1,0], [0,1,1,1],
        [1,0,0,0], [1,0,0,1], [1,0,1,0], [1,0,1,1], [1,1,0,0], [1,1,0,1], [1,1,1,0], [1,1,1,1],
    ];
    my $j = 0;
    for my $i (0 .. length($new_hex) - 1) {
        my $d = $ds->[CORE::hex substr($new_hex, $i, 1)];
        for (@$d) {
            return if $j >= @$v;
            $v->[$j++] = $_;
        }
    }
    $self;
}

sub get_dec {
    my ($self) = @_;
    my $r = 0;
    $r = $r * 2 + $_ for @{$self->{v}};
    $r;
}

sub set_dec {
    my ($self, $new_dec) = @_;
    my $v = $self->{v};
    for (my $i = $#$v; $i >= 0; --$i) {
        $v->[$i] = $new_dec % 2;
        $new_dec >>= 1;
    }
    $self;
}

sub inc {
    my ($self) = @_;
    my $v = $self->{v};
    for (my $i = $#$v; $i >= 0; --$i) {
        last if $v->[$i] ^= 1;
    }
    $self;
}

sub get_bit { $_[0]->{v}->[- $_[1] - 1] }

sub set_bit {
    my ($self, $index, $bit) = @_;
    $self->{v}->[-$index - 1] = $bit;
    $self;
}

sub is_empty {
    my ($self) = @_;
    $_ && return 0 for @{$self->{v}};
    1;
}

1;
