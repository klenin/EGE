# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A05;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::LangTable;

sub arith {
    my ($self) = @_;
    my $v1 = rnd->in_range(1, 9);
    my $v2 = rnd->in_range(1, 9);
    my $v3 = rnd->in_range(2, 4);
    my $ab1 = rnd->pick('a', 'b');
    my @ab2 = rnd->shuffle('a', 'b');

    my $b = EGE::Prog::make_block([
        '=', 'a', \$v1,
        '=', $ab1, [ rnd->pick('+', '-'), 'a', \$v2 ],
        '=', 'b', [ '-', (rnd->coin ? 1 : ()), $ab1 ],
        '=', 'c', [ '+', [ '-', $ab2[0] ], [ '*', \$v3, $ab2[1] ] ],
    ]);

    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C' ] ]);
    $self->{text} =
        'Определите значение переменной <i>c</i> после выполнения ' .
        "следующего фрагмента программы: $lt";

    my $get_c = sub { $b->run_val('c', { @_ }) };

    my @errors;
    for my $var (\$v1, \$v2, \$v3) {
        $$var += 1;
        push @errors, $get_c->();
        $$var -= 2;
        push @errors, $get_c->();
        $$var += 1;
    }
    push @errors, $get_c->(_skip => $_) for 1 .. $b->count_ops;
    my $correct = $get_c->();
    my %seen = ($correct => 1);
    @errors = grep !$seen{$_}++, @errors;

    $self->variants($correct, rnd->pick_n(3, @errors));
}

sub div_mod_common {
    my ($self, $q, $src, $get_fn) = @_;
    my $cc =
        ', вычисляющие результат деления нацело первого аргумента на второй '.
        'и остаток от деления соответственно';
    my $b = EGE::Prog::make_block([
        @$src,
        '#', {
            Basic => EGE::LangTable::unpre("\'\\ и MOD — операции$cc"),
            Pascal => EGE::LangTable::unpre("{div и mod — операции$cc}"),
            Alg => EGE::LangTable::unpre("|div и mod — функции$cc"),
        },
    ]);

    my $get_v = sub {
        my $env = { @_ };
        $b->run($env);
        $get_fn->($env);
    };
    my $correct = $get_v->();
    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Pascal', 'Alg' ] ]);

    $self->{text} = "$q после выполнения следующего фрагмента программы: $lt";

    my @errors;
    push @errors, $get_v->(_replace_op => $_),
        for { '%' => '//' }, { '//' => '%' }, { '%' => '//', '//' => '%' };
    push @errors, $get_v->(_skip => $_) for 1 .. $b->count_ops;

    my %seen = ($correct => 1);
    @errors = grep !$seen{$_}++, @errors;
    $self->variants($correct, rnd->pick_n(3, @errors));
}

sub div_mod_10 {
    my ($self) = @_;
    my $v2 = rnd->in_range(2, 9);
    my $v3 = rnd->in_range(2, 9);
    $self->div_mod_common(
        'Определите значение целочисленных переменных <i>x</i> и <i>y</i>',
        [
            '=', 'x', [ '+', rnd->in_range(1, 9), [ '*', $v2, $v3 ] ],
            '=', 'y', [ '+', [ '%', 'x', 10 ], rnd->in_range(11, 19) ],
            '=', 'x', [ '+', [ '//', 'y', 10 ], rnd->in_range(1, 9) ],
        ],
        sub { "<i>x</i> = $_[0]->{x}, <i>y</i> = $_[0]->{y}" },
    );
}

sub div_mod_rotate {
    my ($self) = @_;
    $self->div_mod_common(
        'Переменные <i>x</i> и <i>y</i> описаны в программе как целочисленные. ' .
        'Определите значение переменной <i>x</i>',
        [
            '=', 'x', rnd->in_range(101, 999),
            '=', 'y', [ '//', 'x', 100 ],
            '=', 'x', [ '*', [ '%', 'x', 100 ], 10 ],
            '=', 'x', [ '+', 'x', 'y' ],
        ],
        sub { $_[0]->{x} },
    );
}

sub digit_by_digit {
    my ($self) = @_;
    my $good = sub { rnd->in_range(10, 18) };
    my $bad1 = sub { sprintf('%02d', rnd->in_range(0, 9)) };
    my $bad2 = sub { 19 };

    $self->variants( map { join '', @$_ }
        [sort { $b <=> $a } $good->(), $good->(), $good->()],
        [sort $good->(), $good->(), $good->()],
        [sort { $b <=> $a } $bad1->(), $good->(), $good->()],
        [sort { $b <=> $a }$bad2->(), $good->(), $good->()]
    );

    $self->{text} = << 'EOL'
Автомат получает на вход два трехзначных числа. По этим числам строится новое
число по следующим правилам.
<ol>
  <li>
    Вычисляются три числа – сумма старших разрядов заданных трехзначных чисел,
    сумма средних разрядов этих чисел, сумма младших разрядов.
  </li>
  <li>
    Полученные три числа записываются друг за другом в порядке убывания (без разделителей).
  </li>
</ol>
<i>Пример. Исходные трехзначные
числа:  835, 196. Поразрядные суммы: 9, 12, 11. Результат: 12119</i>
<br/>Определите, какое из следующих чисел может быть результатом работы автомата.
EOL
}

1;
