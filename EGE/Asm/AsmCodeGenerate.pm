# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Asm::AsmCodeGenerate;

use strict;
use warnings;

use POSIX qw/ceil/;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Prog;

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

sub random_mov { [ 'mov', $_[1], rnd->in_range(1, 255) ]; }

sub random_command {
    my ($self, $type, $reg, $arg) = @_;
    my ($cmds, $arg_range) = @{{
        add => [ [ qw(add sub adc sbb neg) ], [65, 255] ],
        logic => [ [ qw(and or xor test not) ], [1, 255] ],
        shift => [ [ keys %{EGE::Asm::Processor::shift_commands()} ], [1, 3] ],
    }->{$type}};
    my $cmd = rnd->pick(@$cmds);
    $arg //= rnd->in_range(@$arg_range);
    (
        $self->use_cf($cmd) ? [ rnd->pick(qw[stc clc]) ] : (),
        $self->single_arg($cmd) ? [ $cmd, $reg ] : [ $cmd, $reg, $arg ],
    );
}

sub add_command {
    my $self = shift;
    push @{$self->{code}}, [ @_ ];
}

sub add_commands {
    my $self = shift;
    push @{$self->{code}}, @_;
}

sub set_commands {
    my $self = shift;
    $self->{code} = [ @_ ];
}

sub is_integer { $_[0] =~ m/^-?(\d+)$/ }

sub ensure_numeric { $_[0] =~ m/^[\-0-9]/ ? $_[0] : "0$_[0]" }

sub format_command {
    my ($self, $command, $num_format) = @_;
    my ($cmd, @args) = @$command;
    "$cmd " . join ', ', map { is_integer($_) ? ensure_numeric(sprintf $num_format, $_) : $_ } @args;
}

sub format_commands {
    my ($self, $num_format) = @_;
    map $self->format_command($_, $num_format), @{$self->{code}};
}

sub get_code_txt {
    my ($self, $num_format) = @_;
    my $cmd_list = join '<br/>', $self->format_commands($num_format);
    qq~<div class="code"><code>$cmd_list</code></div>~;
}

sub make_reg {
    my ($size, $letter) = @_;
    sprintf { 32 => 'e%sx', 16 => '%sx', 8 => '%s' . rnd->pick('h', 'l') }->{$size}, $letter;
}

sub get_reg {
    my (undef, $size, $not_ecx) = @_;
    make_reg $size, rnd->pick($not_ecx ? qw(a b d) : qw(a b c d));
}

sub get_regs {
    my ($self, @sizes) = @_;
    my @letters = rnd->pick_n(scalar @sizes, 'a'..'d');
    map make_reg($sizes[$_], $letters[$_]), 0..$#letters;
}

sub single_arg {
	my ($self, $cmd) = @_;
	{ not => 1, neg => 1 }->{$cmd};
}

sub use_cf {
	my ($self, $cmd) = @_;
	{ adc => 1, sbb => 1, rcl => 1, rcr => 1 }->{$cmd};
}

sub get_hex_args {
	my($self, $type) = @_;
	no strict 'refs';
	&{"get_hex_args_".$type}();
}

sub get_hex_args_bscan {
    my ($arg1, $arg2) = (0, 0);
    for my $p (3..28) {
        if (rnd->pick(0, 1)) {
            $arg1 += 2 ** $p;
        } 
    }
    ($arg1, $arg2);
}

sub get_hex_args_add {
	my ($arg1, $arg2) = (0, 0);
	for (1..7) {
		my $sum = rnd->in_range(0, 15);
		my $n = rnd->in_range(ceil($sum/2), $sum);
		$arg1 = $arg1*16 + $n;
		$arg2 = $arg2*16 + $sum - $n;
	}
	$_ += rnd->in_range(0, 15) * 16**7 for ($arg1, $arg2);
	($arg1, $arg2);
}

sub get_hex_args_logic {
	my @arr = (0, 0);
	for (1..8) {
		my $n1 = rnd->pick(0, 15);
		my $n2 = rnd->in_range(0, 15);
		my ($i, $j) = rnd->pick_n(2, (0, 1));
		$arr[$i] = $arr[$i]*16 + $n1;
		$arr[$j] = $arr[$j]*16 + $n2;
	}
	@arr;
}

sub get_hex_args_shift {
	my $arg = 0;
	$arg = $arg*16 + rnd->in_range(1, 15) for (1..8);
	($arg, rnd->pick(4, 8, 12));
}

sub move_command {
    my ($self, $from, $to) = @_;
    my $code = $self->{code};
    0 <= $from && $from < @$code or die "Bad from: $from";
    0 <= $to && $to <= @$code or die "Bad to: $to";
    my $c = splice @$code, $from, 1;
    splice @$code, ($from < $to ? $to - 1 : $to), 0, $c;
    $self;
}

sub remove_command {
    my ($self, $id, $count) = @_;
    splice @{$self->{code}}, $id, $count || 1;
    $self;
}

sub generate_bscan_code {
    my ($self, $type) = (@_, 'bscan');
    my ($format_variants, $format_code, $n) = ('%s', '%08Xh', 32);
    my ($reg16, $reg32) = (rnd->pick(qw(si di bp sp)), cgen->get_regs($n));
    my ($arg1, $arg2) = cgen->get_hex_args($type);
    $self->{code} = [];
    $self->add_command( 'mov', $reg32, $arg1 );
    if (rnd->pick(0,1)) {
        $self->add_command( 'bswap', $reg32 );
    }
    my $scan_type = (rnd->pick(0,1) ? ( 'bsr' ) : ( 'bsf' ));
    $self->add_command(( $scan_type, $reg16, $reg32 ));
    ($reg16, $reg32, $format_variants, $format_code);
}

sub generate_simple_code {
	my ($self, $type) = @_;
	my ($format, $n) = (rnd->pick(0,1)) ? ('%s', 8) : ('%08Xh', 32);
	my $reg = $self->get_reg($n);
	$self->{code} = [];
	if ($n == 8) {
        $self->add_commands(
            $self->random_mov($reg),
            $self->random_command($type, $reg));
		$self->{code}->[0]->[2] = rnd->in_range(1, 15) * 16 + rnd->in_range(1, 15) if ($type eq 'shift');
	}
	else {
		my ($arg1, $arg2) = $self->get_hex_args($type);
        $self->add_commands(
            [ 'mov', $reg, $arg1 ],
            $self->random_command($type, $reg, $arg2));
	}
	($reg, $format, $n, cgen->{code}->[0]->[2]);
}

sub cmd { $_[0]->{code}->[$_[1]]->[0] }

sub clear { $_[0]->{code} = []; $_[0]->free_all_registers; }

sub allocate_register {
    my ($self) = @_;
    my $alloc = $self->{allocated_registers} //= {};
    for (@EGE::Asm::Processor::registers) {
        next if $alloc->{$_};
        $alloc->{$_} = 1;
        return $_;
    }
    die 'Not enought registers';
}

sub free_register {
    my ($self, $reg) = @_;
    my $alloc = $self->{allocated_registers} //= {};
    $alloc->{$reg} or die "Register $reg is not allocated";
    delete $alloc->{$reg};
}

sub free_all_registers { $_[0]->{allocated_registers} = {} }

sub compile {
    my ($self, $expr) = @_;
    if ($expr->isa('EGE::Prog::Const')) {
        my $reg = $self->allocate_register;
        $self->add_command('mov', $reg, $expr->{value});
        return $reg;
    }
    if ($expr->isa('EGE::Prog::BinOp')) {
        my $reg_left = $self->compile($expr->{left});
        my $r = $expr->{right};
        my $op = {
            '+' => 'add', '-' => 'sub', '*' => 'imul', '&' => 'and', '|' => 'or', '^' => 'xor'
        }->{$expr->{op}};
        if ($r->isa('EGE::Prog::Const')) {
            $self->add_command($op, $reg_left, $r->{value});
        }
        else {
            my $reg_right = $self->compile($expr->{right});
            $self->add_command($op, $reg_left, $reg_right);
            $self->free_register($reg_right);
        }
        return $reg_left;
    }
    die "Not implemented: $expr";
}

1;
