# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch::Arch04;
use base 'EGE::GenBase::MultipleChoiceFixedVariants';

use strict;
use warnings;
use utf8;

use EGE::Html;
use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub run_selected {
    my ($commands, $selected, $reg) = @_;
    cgen->clear;
    for my $i (0..$#$commands) {
        cgen->add_commands($commands->[$i]) if $selected->[$i];
    }
    proc->run_code(cgen->{code})->get_val($reg);
}

sub try_choose_commands {
    my $self = shift;
    my ($reg1, $reg2) = cgen->get_regs(8, 8);
    my ($arg1, $arg2) = map rnd->in_range(1, 255), 1..2;
    my $arg3 = rnd->in_range_except(1, 255, $arg2);
    my ($cmd1, $cmd2, $cmd3) = map rnd->pick(qw(add sub)), 1..3;
    my $commands = [
        [ 'mov', $reg1, $arg1 ],
        [ $cmd1, $reg1, $arg2 ],
        [ 'mov', $reg2, $reg1 ],
        [ $cmd2, $reg1, $arg3 ],
        [ $cmd3, $reg1, $reg2 ],
    ];
    my @good = (
        [ 1, 0, 1, 1, 1 ],
        [ 1, 1, 1, 0, 1 ],
        [ 1, 0, 1, 0, 1 ],
    );
    my @bad = (
        [ 1, 1, 1, 1, 1 ],
        [ 1, 0, 0, 0, 0 ],
        [ 1, 1, 0, 0, 0 ],
        [ 1, 1, 0, 1, 0 ],
    );

    my @res_good = map run_selected($commands, $_, $reg1), @good;
    my @res_bad = map run_selected($commands, $_, $reg1), @bad;

    my %res_idx = ();
    ++$res_idx{$_} for @res_good, @res_bad;
    return if grep { $res_idx{$_} > 1 } @res_good;

    my $idx = rnd->in_range(0, $#good);
    $self->{text} =
        'Выделите команды, которые следует оставить в программе, ' .
        "чтобы после выполнения полученного кода в регистре $reg1 " .
        "содержалось значение $res_good[$idx]";
    $self->variants(map html->code(cgen->format_command($_, '%d')), @$commands);
    $self->{correct} = $good[$idx];
}

sub choose_commands { 1 until $_[0]->try_choose_commands; }

1;
