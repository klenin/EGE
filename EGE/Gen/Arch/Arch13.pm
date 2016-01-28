# Copyright © 2016 Alexander S. Klenin
# Copyright © 2016 Nikita V. Dobrynin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Arch::Arch13;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;
use EGE::Html;

my $used_registers = 0;

sub get_free_register {
    die $used_registers if $used_registers >= @EGE::Asm::Processor::registers;
    $EGE::Asm::Processor::registers[$used_registers++];
}

sub free_last_register { $used_registers-- if $used_registers > 0 }

my @operators = (
    {
        operators => [
            { asm => 'imul', html_math => '*'    , eval_math => '*', hint => 'Умножение'                 }
        ],
        gen => \&gen_add_sub
    }, {
        operators => [
            { asm => 'add' , html_math => '+'    , eval_math => '+', hint => 'Сложение'                  },
            { asm => 'sub' , html_math => '−'    , eval_math => '-', hint => 'Вычитание'                 }
        ],
        gen => \&gen_add_sub
    }, {
        operators => [
            { asm => 'and' , html_math => '&amp;', eval_math => '&', hint => 'Побитовое И'               },
        ],
        gen => \&gen_add_sub
    }, {
        operators => [
            { asm => 'xor' , html_math => '^'    , eval_math => '^', hint => 'Побитовое исключающее ИЛИ' },
            { asm => 'or'  , html_math => '|'    , eval_math => '|', hint => 'Побитовое ИЛИ'             },
        ],
        gen => \&gen_add_sub
    }
);

my @operators_by_id;

my %operators_by_eval_math;

sub gen_add_sub {
    my $node = shift;
    my @operands = @{$node->{operands}};
    my @operators = @{$node->{operators}};
    my $res_reg = 0;
    my $res_asm_list = [];
    for my $compl_op_pos (0 .. @operands - 1) {
        if (!exists $operands[$compl_op_pos]->{constant}) {
            my $t = $operands[$compl_op_pos]->{gen}->($operands[$compl_op_pos]);
            $res_reg = $t->{reg};
            $res_asm_list = $t->{asm_list};
            if ($compl_op_pos > 0 && $operators[$compl_op_pos - 1]->{eval_math} eq '-') {
                push @$res_asm_list, [ 'neg', $res_reg ];
                $operators[$compl_op_pos - 1] = $operators_by_eval_math{'+'};
            }
            splice @operands, $compl_op_pos, 1;
            last;
        }
    }
    if (!$res_reg) {
        $res_reg = get_free_register();
        my $operand = shift @operands;
        $res_asm_list = [[ 'mov', $res_reg, $operand->{constant} ]];
    }
    for my $op_pos (0 .. @operands - 1) {
        if (exists $operands[$op_pos]->{constant}) {
            push @$res_asm_list, [ $operators[$op_pos]->{asm}, $res_reg, $operands[$op_pos]->{constant} ];
        } else {
            my $t = $operands[$op_pos]->{gen}->($operands[$op_pos]);
            push @$res_asm_list, @{$t->{asm_list}};
            push @$res_asm_list, [ $operators[$op_pos]->{asm}, $res_reg, $t->{reg} ];
            free_last_register;
        }
    }
    { reg => $res_reg, asm_list => $res_asm_list };
}

sub append_operand {
    my ($node, $i, $mutate_brackets, $mutate_operators) = @_;
    my $operand = $node->{operands}->[$i];
    my $res_txt = gen_expression_text($operand, $mutate_brackets, $mutate_operators);
    $node->{priority} < $operand->{priority} && (rnd->coin || !$mutate_brackets) ?
        "($res_txt)" : $res_txt;
}

sub gen_expression_text {
    my ($node, $mutate_brackets, $mutate_operators) = @_;
    return $node->{constant} if exists $node->{constant};
    my $res_txt = '';
    for my $i (0 .. @{$node->{operands}} - 2) {
        my $curr_op = $node->{operators}->[$i];
        $res_txt .=
            append_operand($node, $i, $mutate_brackets, $mutate_operators) . ' ' .
            (rnd->coin && $mutate_operators ?
            $operators_by_id[rnd->in_range_except(0, @operators_by_id - 1, $curr_op->{id})]->{eval_math} :
            $curr_op->{eval_math}) . ' ';
    }
    $res_txt . append_operand($node, @{$node->{operands}} - 1, $mutate_brackets, $mutate_operators);
}

sub get_random_operand {
    { constant => rnd->in_range(1, 10), priority => 0 };
}

sub make_expression {
    my ($n, $op_priority) = @_;
    return get_random_operand() if $n == 1;
    my $operands = [];
    my $operators = [];
    while ($n > 0) {
        my $inner_n = rnd->in_range(1, $n - 1);
        push @$operands, make_expression($inner_n, rnd->in_range_except(0, @operators - 1, $op_priority));
        push @$operators, rnd->pick(@{$operators[$op_priority]->{operators}});
        $n -= $inner_n;
    }
    pop @$operators;
    {
        operands => rnd->shuffle($operands),
        operators => $operators,
        gen => $operators[$op_priority]->{gen},
        priority => $op_priority
    };
}

sub convert_eval_to_html_format {
    my $str = shift;
    for my $op (keys %operators_by_eval_math) {
        my $m = quotemeta ($op);
        $str =~ s/$m/$operators_by_eval_math{$op}->{html_math}/g;
    }
    $str;
}

sub check_for_repeats {
    my ($a, @arr) = @_;
    my $v = eval $a;
    for my $i (@arr) {
        return 1 if $v == eval $i;
    }
    0;
}

sub gen_variants {
    my ($n, $node) = @_;
    my @res = gen_expression_text($node, 0, 0);
    my @mutate_args = ([ 0, 1 ], [ 1, 1 ]);
    for my $i (1 .. $n - 1) {
        my $mutate_arg = rnd->pick(@mutate_args);
        my $curr_variant;
        my $iter = 0;
        do {
            $curr_variant = gen_expression_text($node, @$mutate_arg);
            die if $iter++ > 50;
        } while check_for_repeats($res[0], $curr_variant);
        push @res, $curr_variant;
    }
    @res;
}

sub priority_table_text {
    my $r = html->row('th', qw(Приоритет Операция Описание));
    for my $priority (0 .. @operators - 1) {
        $r .= join '', map html->row('td', ($priority + 1, $_->{html_math}, $_->{hint})),
            @{$operators[$priority]->{operators}};
    }
    html->table($r, { border => 1 });
}

sub init_operators {
    my $i = 0;
    for my $priority (0 .. @operators - 1) {
        for my $op (@{$operators[$priority]->{operators}}) {
            push @operators_by_id, $op;
            $op->{id} = $i++;
            $operators_by_eval_math{$op->{eval_math}} = $op;
        }
    }
}

sub expression_calc {
    my $self = shift;
    $used_registers = 0;
    init_operators();

    my $node = make_expression(rnd->in_range(6, 12), 1);

    my $t = $node->{gen}->($node);
    my @asm_list = @{$t->{asm_list}};
    cgen->set_commands(@asm_list);

    $self->{text} = sprintf
        'Укажите формулу, которую будет вычислять следующий код: ' .
        '<table><tr><td style="padding: 0 40px 0 40px;">%s</td><td>%s</td></tr></table>',
        cgen->get_code_txt('%d'), priority_table_text;

    my @v = gen_variants(4, $node);
    $self->variants(map convert_eval_to_html_format($_), @v);
}

1;
