# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B05;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

my @commands = (
    sub {
        my $v = rnd->in_range(1, 9);
        "прибавь $v",
        "прибавляет к числу на экране $v",
        "прибавляет к нему $v",
        sub { $_[0] + $v }
    },
    sub {
        my $v = rnd->in_range(2, 5);
        "умножь на $v",
        "умножает число на экране на $v",
        "умножает его на $v",
        sub { $_[0] * $v }
    },
    sub {
        'возведи в квадрат',
        'возводит число на экране в квадрат',
        'возводит его в квадрат',
        sub { $_[0] * $_[0] }
    },
);

sub make_cmd {
    my %cmd;
    @cmd{qw(t1 t2 t3 run)} = $_[0]->();
    \%cmd;
}

sub apply {
    my ($cmd, $prg, $value) = @_;
    $value = $cmd->[$_]->{run}->($value) for @$prg;
    $value;
}

sub next_prg {
    my ($cmd, $prg) = @_;
    for (@$prg) {
        return 1 if ++$_ < @$cmd;
        $_ = 0;
    }
    0;
}

sub code { join '', map $_ + 1, @{$_[0]}; }
sub li { join '', map "<li>$_</li>", @_; }

sub same_digit { $_[0] =~ /^(\d)\1+$/; }

sub calculator {
    my ($self) = @_;
    my $num = rnd->in_range(4, 6);

    my ($cmd, $arg, $prg, $result);
    do {
        $cmd = [ map make_cmd($_), rnd->pick_n(2, @commands) ];
        $arg = rnd->in_range(2, 10);
        $prg = [ (0) x $num ];
        my %results;
        ++$results{apply($cmd, $prg, $arg)} while next_prg($cmd, $prg);
        my @r = grep 50 < $_ && $_ < 1000 && $results{$_} == 1, keys %results;
        $result = rnd->pick(@r) if @r;
    } until $result;
    $prg = [ (0) x $num ];
    next_prg($cmd, $prg) until apply($cmd, $prg, $arg) == $result;
    my $code = code($prg);

    my ($sample_prg, $sample_code, $sample_result);
    do {
        $sample_prg = [ map rnd->in_range(0, $#$cmd), 1 .. $num ];
        $sample_code = code($sample_prg);
        $sample_result = apply($cmd, $sample_prg, 1);
    } while
        $sample_code eq $code ||
        $sample_result eq $result ||
        same_digit($sample_code);

    my @sample_prg_list = map $cmd->[$_]->{t1}, @$sample_prg;
    $sample_prg_list[-1] .= ',';

    $self->{text} =
        'У исполнителя Калькулятор две команды, которым присвоены номера: ' .
        '<b><ol> ' . li(map ucfirst($_->{t1}), @$cmd) . '</ol></b> ' .
        "Выполняя первую из них, Калькулятор $cmd->[0]->{t2}, " .
        "а выполняя вторую, $cmd->[1]->{t3}. " .
        "Запишите порядок команд в программе получения из числа $arg " .
        "числа $result, содержащей не более $num команд, указывая лишь номера команд " .
        "(Например, программа $sample_code — это программма " .
        '<b><ul> ' . li(@sample_prg_list) . '</ul></b> ' .
        "которая преобразует число 1 в число $sample_result)";
    $self->{correct} = $code;
    $self->accept_number;
}

1;
