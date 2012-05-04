# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A09;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use List::Util 'min';

use EGE::Random;
use EGE::Bits;
use EGE::Logic;
use EGE::Html;

sub rand_expr_text {
    my $e = EGE::Logic::random_logic_expr(@_);
    ($e, $e->to_lang_named('Logic'));
}

sub tt_row {
    my ($e, $bits, @vars) = @_;
    my $r = EGE::Logic::bits_to_vars($bits, @vars);
    $r->{F} = $e->run($r);
    $r;
}

sub tt_html {
    my ($table, @vars) = @_;
    my $r = html->row_n('th', @vars);
    $r .= html->row_n('td', @$_{@vars}) for @$table;
    html->table($r, { border => 1 });
}

sub check_rows {
    my ($table, $e) = @_;
    for (@$table) {
        return 0 if $e->run($_) != $_->{F};
    }
    return 1;
}

sub truth_table_fragment {
    my ($self) = @_;
    my @vars = qw(X Y Z);
    my ($e, $e_text) = rand_expr_text(@vars);
    my @rows = sort { $a <=> $b } rnd->pick_n(3, 0 .. 2 ** @vars - 1);
    my @bits = map EGE::Bits->new->set_size(4)->set_dec($_), @rows;
    my $fragment = [ map tt_row($e, $_, @vars), @bits ];
    my %seen = ($e_text => 1);
    my @bad;
    while (@bad < 3) {
        my ($e1, $e1_text);
        do {
            ($e1, $e1_text) = rand_expr_text(@vars);
        } while $seen{$e1_text}++;
        push @bad, $e1_text unless check_rows($fragment, $e1);
    }
    my $tt_text = tt_html($fragment, @vars, 'F');
    $self->{text} =
        'Символом F обозначено одно из указанных ниже логических выражений ' .
        'от трёх аргументов X, Y, Z. ' .
        "Дан фрагмент таблицы истинности выражения F: \n$tt_text\n" .
        'Какое выражение соответствует F?';
    $self->variants($e_text, @bad);
}

sub _build_tree {
    my ($len) = @_;
    return undef unless $len;
    if (rnd->coin()) {
        return { l => _build_tree($len - 1), r => _build_tree($len - 1) }
    } else {
        return { (rnd->coin() ? 'l' : 'r') => _build_tree($len - 1)  }
    }
}

sub _gain_codes {
    my ($node, $res, $accum) = @_;
    if ($node->{r}) {
        _gain_codes($node->{r}, $res, $accum . 1)
    } else {
        push @$res, $accum . 1
    }
    if ($node->{l}) {
        _gain_codes($node->{l}, $res, $accum . 0)
    } else {
        push @$res, $accum . 0
    }
}

sub _build_codes {
    my ($len, $t) = @_;
    my $res = [];
    $t //= _build_tree($len);
    _gain_codes($t, $res, '');
    $res
}

sub _get_prefix { substr($_[0], 0, length($_[0]) - 1) }

sub _add_suffixes { ($_[0] . 0, $_[0] . 1) }

sub find_var_len_code {
    my ($self) = @_;
    my @codes = rnd->shuffle(@{ _build_codes(3) });
    my $ans = shift @codes;
    @codes = @codes[0 .. rnd->in_range(2, min($#codes, 5))];
    my @bad = map { _add_suffixes($_) } @codes;
    for (map { _get_prefix($_) } grep { length($_) > 1 } @codes) {
        push @bad, $_ unless $_ ~~ @bad
    }
    @bad = rnd->shuffle(@bad);
    $self->variants($ans, @bad[0 .. 2]);

    my @alph = ('A' .. 'G');
    $self->{text} .= sprintf
        'Для кодирования некоторой последовательности, состоящей из букв %s' .
        ', решили использовать неравномерный двоичный код, позволяющий ' .
        ' однозначно декодировать двоичную последовательность, появляющуюся на ' .
        'приёмной стороне канала связи. Использовали код: %s . Укажите, каким ' .
        'кодовым словом может быть закодирована буква Д. ' .
        'Код должен удовлетворять свойству однозначного декодирования.',
        (join ', ', @alph[0 .. $#codes]),
        join ', ', map { shift(@alph) . '-' . $_ } @codes;
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item truth_table_fragment

=item find_var_len_code

=back


=head2 Генератор find_var_len_code

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание A9.

=head3 Описание

=over

=item *

Случайным образом строитя двоичное дерево.

=item *

После обхода дерева получаются коды.

=item *

Выбирается один код для ответа и несколько кодов для условия

=item *

В качестве деструкторов берутся либо префиксы кодов из условия, либо
к кодам из условия добавляются суффиксы.

=item *

