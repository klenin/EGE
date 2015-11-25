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
use EGE::NumText;

my $start_num;
my $end_num;
my @curr_comms;
my @din;

sub solve {
    my $n = shift;
    return 0 if $n < $start_num;

    my $v = \$din[$n - $start_num];
    if (!$$v) {
        $$v += solve($_->{rev}->($n)) for @curr_comms;
    }
    $$v;
}

sub make_plus {
    my ($arg) = @_;
    { text => "прибавить $arg", rev => sub { $_[0] - $arg } }
}

sub make_mult {
    my ($arg) = @_;
    { text => "умножить на $arg", rev => sub { $_[0] % $arg ? 0 : int($_[0] / $arg) } }
}

sub calculator_find_prgm_count {
    my ($self) = @_;

    my ($answer, $iter);
    do {
        $start_num = rnd->in_range(1, 5);
        $end_num = rnd->in_range(14, 25 + $start_num);
        @din = (1, (0) x ($end_num - $start_num + 1));
        @curr_comms = (
            make_plus($start_num % 2 == $end_num % 2 ? 2 : 1),
            map make_mult($_), rnd->pick_n(rnd->coin + 1..5));
        $answer = solve($end_num);
    } until (10 < $answer && $answer < 100 || ++$iter > 20);

    $self->{text} = sprintf
        'У исполнителя Калькулятор %s команды, которым присвоены номера: %s ' .
        'Сколько есть программ, которые число %d преобразуют в число %d?',
        num_by_words(scalar @curr_comms, 1),
        html->ol(join '', map html->li($_->{text}), @curr_comms),
        $start_num, $end_num;

    $self->{correct} = $answer;
    $self->accept_number;
}

1;
