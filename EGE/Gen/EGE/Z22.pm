# Copyright © 2010 Alexander S. Klenin
# Copyright © 2015 R. Kravchuk
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::EGE::Z22;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;

my %operator_to_str = (
    '+' => 'прибавить',
    '*' => 'умножить на'
);

my @nums = ('две', 'три');

my $start_num;
my $end_num;
my @curr_comms;

my @orig_mul_ops = (2, 3);
my @orig_add_ops = (1, 2, 3);

my @din;

sub solve {
    my $n = shift;

    return 1 if $n == $start_num;
    return 0 if $n < $start_num;
    return $din[$n] if $din[$n];

    for my $cmd (@curr_comms) {
        my $op = $cmd->{operand};
        if ($cmd->{operator} eq '*') {
            $din[$n] += solve($n / $op) if $n % $op == 0;
        } else {
            $din[$n] += solve($n - $op);
        }
    }
    $din[$n];
}

sub gen_comm {
    { operator => $_[0], operand => $_[1], str => $operator_to_str{$_[0]} };
}

sub gen_comms {
    my $n = shift;

    my $operand = $start_num % 2 || $end_num % 2 ? 1 : 2;
    my @res = gen_comm('+', $operand);
    my @add_ops = grep $_ != $operand, rnd->shuffle(@orig_add_ops);
    my @mul_ops = rnd->shuffle(@orig_mul_ops);

    push @res, gen_comm('*', pop @mul_ops);

    if ($n == 3) {
        my $operator = rnd->pick('+', '*');
        $operand = $operator eq '+' ? pop @add_ops : pop @mul_ops;
        push @res, gen_comm($operator, $operand);
    }
    @res;
}

sub calculator_find_prgm_count {
    my ($self) = @_;
    $start_num = rnd->in_range(1, 5);
    $end_num = rnd->in_range(14, 30 - 5 + $start_num);
    @din = map 0, $start_num..$end_num;
    my $comm_count = rnd->in_range(2, scalar @nums + 1);
    @curr_comms = gen_comms($comm_count);

    $self->{text} = 
        "У исполнителя Калькулятор $nums[$comm_count - 2] команды, которым присвоены номера: ".
        html->ol(join '', map html->li($_->{str} . ' ' . $_->{operand}), @curr_comms) .
        "Сколько есть программ, которые число $start_num преобразуют в число $end_num?";

    $self->{correct} = solve($end_num);
    $self->accept_number;
}

1;
