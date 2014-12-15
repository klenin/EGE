# Copyright © 2010-2013 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A05;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use Storable qw(dclone);

use EGE::Random;
use EGE::Prog;
use EGE::LangTable;
use EGE::Bits;

sub is_binop { $_[0]->isa('EGE::Prog::BinOp') }

sub without_op {
    my ($expr, $index) = @_;
    my $count = 0;
    dclone($expr)->visit_dfs(sub {
        $_[0] = $_[0]->{left} || $_[0] if is_binop($_[0]) && ++$count == $index
    });
}

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

    my $get_c = sub { $_[0]->run_val('c', {}) };

    my @errors;
    for my $var (\$v1, \$v2, \$v3) {
        $$var += 1;
        push @errors, $get_c->($b);
        $$var -= 2;
        push @errors, $get_c->($b);
        $$var += 1;
    }
    push @errors, $get_c->(without_op($b, $_)) for 1 .. $b->count_if(\&is_binop);
    my $correct = $get_c->($b);
    my %seen = ($correct => 1);
    @errors = grep !$seen{$_}++, @errors;

    $self->variants($correct, rnd->pick_n(3, @errors));
}

sub replace_ops {
    my ($expr, $repls) = @_;
    dclone($expr)->visit_dfs(sub {
        my $newop = $repls->{$_[0]->{op} || ''} or return;
        $_[0]->{op} = $newop;
    });
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
        my $env = {};
        $_[0]->run($env);
        $get_fn->($env);
    };
    my $correct = $get_v->($b);
    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Pascal', 'Alg' ] ]);

    $self->{text} = "$q после выполнения следующего фрагмента программы: $lt";

    my @errors;
    push @errors, $get_v->(replace_ops($b, $_)),
        for { '%' => '//' }, { '//' => '%' }, { '%' => '//', '//' => '%' };
    push @errors, $get_v->(without_op($b, $_)) for 1 .. $b->count_if(\&is_binop);

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

sub random_0_1 {
    my ($zeroes, $ones, $used, $cond) = @_;
    $cond ||= sub { 1 };
    my $bits = EGE::Bits->new;
    do { $bits->set_bin([ rnd->shuffle((0) x $_[0], (1) x $_[1]) ], 1) }
        until !$used->{$bits->get_bin} && $cond->($bits);
    $used->{$bits->get_bin} = 1;
    $bits;
}

sub crc {
    my ($self) = @_;
    my ($digits, $digits_text, $control_text) = @{rnd->pick(
        [6, qw(шести седьмой)],
        [7, qw(семи восьмой)],
        [8, qw(восьми девятый)],
    )};
    my $zero_out = '0' x ($digits + 1);

    my $ones = int($digits / 2) + int($digits / 2) % 2;
    my $used = {};
    my $sample_0 = random_0_1($digits - $ones, $ones, $used, sub { $_[0]->xor_bits == 0 })->get_bin;
    my $sample_1 = random_0_1($digits - $ones + 1, $ones - 1, $used, sub { $_[0]->xor_bits == 1 })->get_bin;

    my @msg = map random_0_1($digits - $ones, $ones, $used), 0 .. 2;
    push @{$_->{v}}, $_->xor_bits for @msg;

    my ($unchanged, $single, $double)= rnd->shuffle(0 .. 2);
    my @bad = map $_->dup, @msg;
    $bad[$single]->flip(rnd->in_range(0, $digits));
    $bad[$double]->flip($_) for rnd->pick_n(2, 0 .. $digits);

    my $msg_as_text = sub {
        my @cmsg = @bad;
        undef $cmsg[$_] for @_;
        '<tt>' . join(' ', map { $_ ? $_->get_bin : $zero_out } @cmsg) . '</tt>';
    };

    $self->variants(map($msg_as_text->($_), 0 .. 2), $msg_as_text->($single, $double));
    $self->{correct} = $single;
    $self->{text} =
        "<p>В не­ко­то­рой ин­фор­ма­ци­он­ной си­сте­ме ин­фор­ма­ция ко­ди­ру­ет­ся дво­ич­ны­ми ${digits_text}раз­ряд­ны­ми сло­ва­ми. " .
        "При пе­ре­да­че дан­ных воз­мож­ны их ис­ка­же­ния, по­это­му в конец каж­до­го слова до­бав­ля­ет­ся $control_text " .
        '(кон­троль­ный) раз­ряд таким об­ра­зом, чтобы сумма раз­ря­дов но­во­го слова, счи­тая кон­троль­ный, была чётной. ' .
        "На­при­мер, к слову <tt>$sample_0</tt> спра­ва будет до­бав­лен <tt>0</tt>, а к слову <tt>$sample_1</tt> — <tt>1</tt>.</p>" .
        '<p>После приёма слова про­из­во­дит­ся его об­ра­бот­ка. При этом про­ве­ря­ет­ся сумма его раз­ря­дов, вклю­чая кон­троль­ный. ' .
        'Если она нечётна, это озна­ча­ет, что при пе­ре­да­че этого слова про­изошёл сбой, ' .
        "и оно ав­то­ма­ти­че­ски за­ме­ня­ет­ся на за­ре­зер­ви­ро­ван­ное слово <tt>$zero_out</tt>. " .
        'Если она чётна, это озна­ча­ет, что сбоя не было или сбоев было боль­ше од­но­го. В этом слу­чае при­ня­тое слово не из­ме­ня­ет­ся.</p>' .
        '<p>Ис­ход­ное со­об­ще­ние</p><pre>' . join(' ', map $_->get_bin, @msg) .
        '</pre><p>было при­ня­то в виде</p><pre>' . $msg_as_text->() .
        '</pre><p>Как будет вы­гля­деть при­ня­тое со­об­ще­ние после об­ра­бот­ки?</p>';
}

1;
