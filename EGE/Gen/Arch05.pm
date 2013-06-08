# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch05;
use base 'EGE::GenBase::Sortable';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub sort_commands {
    my $self = shift;
    my ($reg1, $reg2, $arg, $cmd_shift) = $self->init_params(8);
    my $cmd = rnd->pick(qw(add sub and or xor));
    my $commands = [
        [ 'mov', $reg1, $arg ],
        [ $cmd_shift, $reg1, 4 ],
        [ 'mov', $reg2, $reg1 ],
        [ $cmd, $reg1, $reg2 ],
    ];
    $self->formated_variants('<code>%s</code>',
        map cgen->format_command($_, $_->[2] eq '4' ? '%d' : '%02Xh'), @$commands);
    my @good = (
        [ 0, 1, 2, 3 ],
        [ 0, 2, 1, 3 ],
        [ 0, 2, 3, 1 ],
    );
    my @res = map $self->run_ordered($commands, $_, $reg1), @good;
    $self->sort_commands if !$self->choose_correct($reg1, \@res, \@good, '%02Xh');
}

sub sort_commands_stack {
    my $self = shift;
    my ($reg1, $reg2, $arg, $cmd_shift) = $self->init_params(16);
    my $commands = [
        [ 'mov', $reg1, $arg ],
        [ $cmd_shift, $reg1, 4 ],
        [ 'push', $reg1 ],
        [ 'pop', $reg2 ],
        [ 'add', $reg1, $reg2 ],
    ];
    $self->formated_variants('<code>%s</code>',
        map cgen->format_command($_, ($_->[2] // '') eq '4' ? '%d' : '%02Xh'), @$commands);
    my @good = (
        [ 0, 1, 2, 3, 4 ],
        [ 0, 2, 3, 4, 1 ],
    );
    my @bad = ([ 0, 2, 3, 1, 4 ]);
    my @res = map $self->run_ordered($commands, $_, $reg1), @good, @bad;
    $self->sort_commands_stack if !$self->choose_correct($reg1, \@res, \@good, '%04Xh');
}

sub init_params {
    my ($self, $bits) = @_;
    my ($reg1, $reg2) = cgen->get_regs($bits, $bits);
    my $arg = rnd->in_range(1, 15) * 16 + rnd->in_range(1, 15);
    my $cmd_shift = rnd->pick(qw(shl shr sal sar rol ror));
    ($reg1, $reg2, $arg, $cmd_shift);
}

sub choose_correct {
    my ($self, $reg1, $res, $correct, $format) = @_;
    my %res_idx;
    ++$res_idx{$_} for @$res;
    return if grep $res_idx{$res->[$_]} > 1, 0 .. $#$correct;
    my $idx = rnd->in_range(0, $#$correct);
    my $hex_val = sprintf $format, $res->[$idx];
    $self->{text} =
        'Расположите команды в такой последовательности, ' .
        "чтобы после их выполнения в регистре $reg1 содержалось значение $hex_val:";
    $self->{correct} = $correct->[$idx];
}

sub run_ordered {
    my ($self, $commands, $order, $reg) = @_;
    cgen->clear;
    cgen->add_commands($commands->[$_]) for @$order;
    proc->run_code(cgen->{code})->get_val($reg);
}

1;
