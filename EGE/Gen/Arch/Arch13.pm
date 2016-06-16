# Copyright © 2016 Alexander S. Klenin
# Copyright © 2016 Nikita V. Dobrynin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Arch::Arch13;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use Storable qw(dclone);

use EGE::Asm::AsmCodeGenerate;
use EGE::Asm::Processor;
use EGE::Html;
use EGE::Prog qw(make_expr);
use EGE::Random;

sub is_negative {
    my ($op, $left, $right) = @_;
    $op eq '-' && $left->run < $right->run;
}

sub make_random_expr {
    my ($n) = @_;
    $n or return make_expr rnd->in_range(1, 10);
    my $split = rnd->in_range(0, $n - 1);
    my ($left, $right) = map make_random_expr($_), $split, $n - $split - 1;
    my $op = rnd->pick('+', '-', '*', '|', '&', '^');
    # Гарантировать, что не возникнут отрицательные числа.
    make_expr [ $op, is_negative($op, $left, $right) ? ($right, $left) : ($left, $right) ];
}

sub is_binop { $_[0]->isa('EGE::Prog::BinOp') }

sub mutate_op {
    my ($expr) = @_;
    my @ops = ('+', '*', '|', '&', '^', is_negative('-', $expr->children) ? () : ('-'));
    $expr->{op} = rnd->pick_except($expr->{op}, @ops);
}

my $perl = EGE::Prog::Lang::Perl->new;

sub mutate_prio {
    my ($expr) = @_;
    my $prio = $perl->{prio};
    my ($left, $right) = $expr->children;
    # Проверяем левый поворот первым, чтобы слегка сдвинуть вправо
    # точку расхождения с правильным ответом.
    if (
        is_binop($right) && $prio->{$right->{op}} != $prio->{$expr->{op}} &&
        !is_negative($expr->{op}, $left, $right->{left})
    ) {
        $expr->rotate_left;
    }
    elsif (
        is_binop($left) && $prio->{$left->{op}} != $prio->{$expr->{op}} &&
        !is_negative($expr->{op}, $right, $left->{right})
    ) {
        $expr->rotate_right;
    }
}

sub mutate_value {
    my ($expr) = @_;
    if ($expr->isa('EGE::Prog::Const')) {
        $expr->{value} = rnd->in_range_except(1, 10, $expr->{value});
    }
    elsif (is_binop($expr)) {
        mutate_value(rnd->pick($expr->children));
    }
}

sub mutate_expr {
    my ($orig, $values) = @_;
    for (my $iter = 0; $iter < 50; ++$iter) {
        my $copy = dclone($orig);
        my $op = rnd->pick($copy->gather_if(\&is_binop));
        mutate_value($op) if $iter > 20;
        $values->{$copy->run}++ or return $copy;
        if (rnd->coin) {
            mutate_op($op);
        }
        else {
            mutate_prio($op);
            next if is_negative($op->{op}, $op->children);
        }
        $values->{$copy->run}++ or return $copy;
    }
    # Одиночных исправлений недостаточно -- использовать кумулятивные исправления.
    my $copy = dclone($orig);
    for (my $iter = 0; $iter < 50; ++$iter) {
        mutate_value($copy);
        $values->{$copy->run}++ or return $copy;
    }
    die join ',', $orig->to_lang_named('Perl'), keys %$values;
}

sub priority_table_text {
    html->table([
        html->row('th', qw(Приоритет Операция Описание)),
        map html->row('td', @$_),
            [ 1, '*',     'Умножение'                 ],
            [ 2, '+',     'Сложение'                  ],
            [ 2, '−',     'Вычитание'                 ],
            [ 3, '&amp;', 'Побитовое И'               ],
            [ 4, '^',     'Побитовое исключающее ИЛИ' ],
            [ 4, '|',     'Побитовое ИЛИ'             ],
        ], { border => 1 });
}

sub expression_calc {
    my ($self) = @_;
    my $expr = make_random_expr(rnd->in_range(8,9));
    cgen->clear;
    cgen->compile($expr);
    $self->{text} = sprintf
        'Укажите формулу, которую будет вычислять следующий код: ' .
        html->table(html->tr_([
            html->td(cgen->get_code_txt('%d'), { html->style(padding => '0 40px 0 40px') }),
            html->td(priority_table_text) ]));
    my $expr_value = $expr->run;
    my $values = { $expr_value => 1 };
    my @bad = map mutate_expr($expr, $values), 1..4;
    $expr->run == $expr_value or die 1;
    proc->run_code(cgen->{code})->get_val('eax') == $expr_value or die 2;
    $self->variants(map html->code($_->to_lang_named('Perl', { html => 1 })), $expr, @bad);
}

1;
