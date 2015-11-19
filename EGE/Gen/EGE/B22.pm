# Copyright © 2010 Alexander S. Klenin
# Copyright © 2015 R. Kravchuk
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::EGE::B22;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

my @comms = (
	{str => 'прибавить', operator => '+'},
	{str => 'умножить на', operator => '*'}
);

my @nums = ('две', 'три');

my $min;
my $max;
my @curr_comms;

my @mul_ops = (2, 3);
my @add_ops = (1, 2, 3);

my @din = map 0, 1..50;

sub solve {
	my $n = shift;
	return 1 if $n == $min;
	if ($n < $min) {
		return 0;
	}
	if ($din[$n]) {
		return $din[$n];
	}
	for (my $i = 0; $i < scalar @curr_comms; $i++) {
		my $op = $curr_comms[$i]{operand};
		if ($curr_comms[$i]{comm}{operator} eq '*') {
			if ($n % $op == 0) {
				$din[$n] += solve($n / $op);
			}
		} else {
			$din[$n] += solve($n - $op);
		}
	}
	return $din[$n];
}

sub gen_comm {
	if (scalar @_ == 2) {
		(my $comm, my $op) = @_;
		if ($comm) {
			@mul_ops = grep $_!= $op, @mul_ops;
		} else {
			@add_ops = grep $_!= $op, @add_ops;
		}
		return {comm => $comms[$comm], operand => $op};
	}
	if (scalar @_ == 1) {
		my $comm = shift;
		my $op;
		if ($comm) {
			$op = pop @mul_ops;
		} else {
			$op = pop @add_ops;
		}
		return {comm => $comms[$comm], operand => $op};
	}
	my $mul = rnd->coin();
	if ($mul) {
		if (scalar @mul_ops) {
			my $op = pop @mul_ops;
			if ($min * $op > $max) {
				return gen_comm();
			} else {
				return {comm => $comms[1], operand => $op};
			}
		}
	}
	return {comm => $comms[0], operand => pop @add_ops}
}

sub gen_comms {
	my $n = shift;
	my @res;
	if (!($min % 2) and !($max % 2)) {
		@res = (gen_comm(0, 2));
	} else {
		@res = (gen_comm(0, 1));
	}
	
	@add_ops = rnd->shuffle(@add_ops);
	@mul_ops = rnd->shuffle(@mul_ops);
	
	push @res, gen_comm(1);
	if ($n == 3) {
		push @res, gen_comm();
	}
	return @res;
}

sub calculator_find_prgm_count {
	my ($self) = @_;
	$min = rnd->in_range(1, 5);
	$max = rnd->in_range(14, 30 - 5 + $min);
	my $comm_count = rnd->in_range(2, scalar @nums + 1);
	@curr_comms = gen_comms($comm_count);
	
	$self->{text} = "<p>У исполнителя Калькулятор ".$nums[$comm_count-2]." команды, ".
					"которым присвоены номера: </p><ol>";
	for (my $i = 0; $i < $comm_count; $i++) {
		$self->{text}.="<li>".$curr_comms[$i]{comm}{str}.' '.$curr_comms[$i]{operand}."</li>";
	}
	$self->{text}.="</ol> Сколько есть программ, которые число $min преобразуют в число $max?";
	$self->{correct} = solve($max);
	$self->accept_number;	
}

1;