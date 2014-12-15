# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch::Arch05;
use base 'EGE::GenBase::Sortable';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub sort_commands {
    my $self = shift;
    1 until $self->try_gen_sort(
        bits => 8, res_format => '%02Xh',
        commands => sub {
            my ($reg1, $reg2, $arg, $cmd_shift) = @_;
            [ 'mov', $reg1, $arg ],
            [ $cmd_shift, $reg1, 4 ],
            [ 'mov', $reg2, $reg1 ],
            [ rnd->pick(qw(add sub and or xor)), $reg1, $reg2 ],
        },
        good => [
            [ 0, 1, 2, 3 ],
            [ 0, 2, 1, 3 ],
            [ 0, 2, 3, 1 ],
        ],
        bad => [],
    );
    $self;
}

sub sort_commands_stack {
    my $self = shift;

    1 until $self->try_gen_sort(
        bits => 16, res_format => '%04Xh',
        commands => sub {
            my ($reg1, $reg2, $arg, $cmd_shift) = @_;
            [ 'mov', $reg1, $arg ],
            [ $cmd_shift, $reg1, 4 ],
            [ 'push', $reg1 ],
            [ 'pop', $reg2 ],
            [ 'add', $reg1, $reg2 ],
        },
        good => [
            [ 0, 1, 2, 3, 4 ],
            [ 0, 2, 3, 4, 1 ],
        ],
        bad => [ [ 0, 2, 3, 1, 4 ] ],
    );
    $self;
}

sub try_gen_sort {
    my ($self, %p) = @_;

    my ($reg1, $reg2) = cgen->get_regs($p{bits}, $p{bits});
    my $arg = rnd->in_range(1, 15) * 16 + rnd->in_range(1, 15);
    my $cmd_shift = rnd->pick(qw(shl shr sal sar rol ror));
    my $commands = [ $p{commands}->($reg1, $reg2, $arg, $cmd_shift) ];

    my @res = map run_ordered($commands, $_, $reg1), @{$p{good}}, @{$p{bad}};
    my %res_idx;
    ++$res_idx{$_} for @res;
    return if grep $res_idx{$res[$_]} > 1, 0 .. $#{$p{good}};

    my $idx = rnd->in_range(0, $#{$p{good}});
    my $hex_val = sprintf $p{res_format}, $res[$idx];
    $self->{text} =
        'Расположите команды в такой последовательности, ' .
        "чтобы после их выполнения в регистре $reg1 содержалось значение $hex_val:";
    $self->formated_variants('<code>%s</code>',
        map cgen->format_command($_, ($_->[2] // '') eq '4' ? '%d' : '%02Xh'), @$commands);
    $self->{correct} = $p{good}->[$idx];
}

sub run_ordered {
    my ($commands, $order, $reg) = @_;
    cgen->clear;
    cgen->add_commands($commands->[$_]) for @$order;
    proc->run_code(cgen->{code})->get_val($reg);
}

1;
