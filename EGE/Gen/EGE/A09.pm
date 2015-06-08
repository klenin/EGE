# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A09;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use List::Util 'min';

use EGE::Random;
use EGE::Bits;
use EGE::Logic;
use EGE::Html;
use EGE::Russian;

sub rand_expr_text {
    my $e = EGE::Logic::random_logic_expr(@_);
    ($e, $e->to_lang_named('Logic', { html => 1 }));
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
    !$len ? undef :
    rnd->coin ? { l => _build_tree($len - 1), r => _build_tree($len - 1) } :
    { rnd->pick(qw(l r)) => _build_tree($len - 1) };
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
    $t //= _build_tree($len); #/
    _gain_codes($t, $res, '');
    $res;
}

sub find_var_len_code {
    my ($self) = @_;
    my @codes = @{_build_codes(3)};
    (my $ans, @codes) = rnd->pick_n(rnd->in_range(3, min(scalar @codes, 6)), @codes);
    my @bad = map { $_ . 0, $_ . 1, length($_) > 1 ? substr($_, 0, -1) : () } @codes;
    $self->variants($ans, rnd->pick_n(3, keys %{{ map { $_ => 1 } @bad }}));

    my @alph = ('A' .. 'Z')[0..$#codes];
    $self->{text} .= sprintf
        'Для кодирования некоторой последовательности, состоящей из букв %s, ' .
        'решили использовать неравномерный двоичный код, позволяющий ' .
        'однозначно декодировать двоичную последовательность, появляющуюся на ' .
        'приёмной стороне канала связи. Использовали код: %s. ' .
        'Укажите, каким кодовым словом может быть закодирована буква %s. ' .
        'Код должен удовлетворять свойству однозначного декодирования.',
        (join ', ', @alph),
        (join ', ', map "$alph[$_]−$codes[$_]", 0..$#codes),
        ++(my $last = $alph[-1]);
}

sub error_correction_code {
    my ($self) = @_;
    my $digits = rnd->in_range(5, 6);
    my %used;
    my @letters = map { bits => EGE::Bits->new->set_size($digits), letter => $_ }, qw(А Б В); 
    for my $l (@letters) {
        do {
            $l->{bits}->set_dec(rnd->in_range(0, 2 ** $digits - 1));
        } while $used{$l->{bits}->get_dec};
        $used{$l->{bits}->get_dec} = 1;
        $used{$l->{bits}->dup->flip($_)->get_dec} = 1 for 0 .. $digits - 1;
    }
    my @msg = (rnd->shuffle(@letters), rnd->pick(@letters));
    my $sample = rnd->pick(@letters);
    my $msg_with_errors = sub {
        my %errors; undef @errors{@_, -1};
        join '', map exists $errors{$_} ? 'x' : $msg[$_]->{letter}, 0 .. $#msg;
    };
    my @error_variants = map [ rnd->pick_n($_, 0 .. $#msg) ], rnd->pick_n(4, 0 .. @msg);
    $self->variants(map $msg_with_errors->(@$_), @error_variants);
    my %correct; undef @correct{@{$error_variants[0]}, -1};
    $self->{text} =
        "<p>Для передачи данных по каналу связи используется $digits-битовый код. " .
        'Сообщение содержит только буквы ' . EGE::Russian::join_comma_and(map $_->{letter}, @letters) .
        ', которые кодируются следующими кодовыми словами:</p><p>' .
        join(', ', map { "$_->{letter} – <tt>" . $_->{bits}->get_bin . '</tt>' } @letters) . '.</p>' .
        '<p>При передаче возможны помехи. Однако некоторые ошибки можно попытаться исправить. ' .
        'Любые два из этих трёх кодовых слов отличаются друг от друга не менее чем в трёх позициях. ' .
        'Поэтому если при передаче слова произошла ошибка не более чем в одной позиции, ' .
        'то можно сделать обоснованное предположение о том, какая буква передавалась. ' .
        '(Говорят, что «код исправляет одну ошибку».) Например, если получено кодовое слово <tt>' .
        $sample->{bits}->dup->flip(rnd->in_range(0, $digits - 1))->get_bin . '</tt>, считается, ' .
        "что передавалась буква $sample->{letter}. " .
        "(Отличие от кодового слова для $sample->{letter} только в одной позиции, " .
        'для остальных кодовых слов отличий больше.) ' .
        'Если принятое кодовое слово отличается от кодовых слов для букв ' .
        join(', ', map $_->{letter}, @letters) .
        ' более чем в одной позиции, то считается, что произошла ошибка (она обозначается ‘x’).</p>' .
        '<p>Получено сообщение <tt>' .
        join(' ',
            map $msg[$_]->{bits}->dup->flip(rnd->pick_n($correct{$_} ? 2 : 1, 0 .. $digits - 1))->get_bin,
            0 .. $#msg) .
        '</tt>. Декодируйте это сообщение — выберите правильный вариант.</p>';
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

