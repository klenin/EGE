# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B04;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use List::Util qw(sum first);
use POSIX qw(ceil);

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;

sub make_xx {[
    '*', map rnd->pick('X', [ '+', 'X', 1 ], [ '-', 'X', 1 ]), 1 .. 2
]}

sub make_side {
    [ rnd->pick(qw(> < >= <=)), make_xx(), rnd->in_range(30, 99) ]
}

sub find_first {
    my ($v, $q) = @_;
    $q->[$_] == $v and return $_ for 0 .. $#$q;
    -1;
}

sub find_last {
    my ($v, $q) = @_;
    $q->[-$_] == $v and return @$q - $_ for 1 .. @$q;
    -1;
}

sub between { $_[1] <= $_[0] && $_[0] <= $_[2] }

sub impl_border {
    my ($self) = @_;
    my $n = 15;

    my ($e, @values);
    do {
        $e = EGE::Prog::make_expr([ '=>', make_side, make_side ]);
        @values = map $e->run({ X => $_ }), 0 .. $n;
    } until between sum(@values), 1, $n;

    my $et = html->cdata($e->to_lang_named('Logic'));

    my $facet = first { between $_->{v}, 1, $n - 1 } rnd->shuffle(map {
        t1 => [ qw(наименьшее наибольшее) ]->[$_ / 2],
        t2 => [ qw(ложно истинно) ]->[$_ % 2],
        v => ($_ < 2 ? \&find_first : \&find_last)->($_ % 2, \@values),
    }, 0 .. 3);
    $self->{text} =
        "Каково $facet->{t1} целое число X, " .
        "при котором $facet->{t2} высказывание $et?";
    $self->{correct} = $facet->{v};
    $self->accept_number;
}

sub _next_ptrn_lex {
    my ($ptrn, $alph_len) = @_;
    my $i = $#$ptrn;
    while ($i > -1 && $ptrn->[$i] == $alph_len - 1) {
        $ptrn->[$i--] = 0
    }
    ++$ptrn->[$i] if $i > -1;
    $i == -1 ? undef : $ptrn
}

sub _prev_ptrn_lex {
    my ($ptrn, $alph_len) = @_;
    my $i = $#$ptrn;
    while ($i > -1 && !$ptrn->[$i]) {
        $ptrn->[$i--] = $alph_len - 1
    }
    --$ptrn->[$i] if $i > -1;
    $i == -1 ? undef : $ptrn
}

sub _ptrn_to_str {
    my ($ptrn, $alph) = @_;
    join '', map { $alph->[$_] } @$ptrn
}

sub lex_order {
    my ($self) = @_;
    my $alph_len = rnd->in_range(3, 5);
    my $ptrn_len = rnd->in_range(4, 6);
    my $delta = rnd->in_range(1, $alph_len);
    my $alph = [sort( rnd()->pick_n($alph_len, qw(А Е И О У Э Ю Я)) )];

    my $ptrn = [($alph_len - 1) x $ptrn_len];
    _prev_ptrn_lex($ptrn, $alph_len) for 1 .. $delta;
    $self->{correct} = _ptrn_to_str($ptrn, $alph);
    my $pos = $alph_len**$ptrn_len - $delta;

    $ptrn = [(0) x $ptrn_len];
    my $ptrn_list = html->li( _ptrn_to_str($ptrn, $alph) );
    for (0 .. $alph_len - 1) {
        _next_ptrn_lex($ptrn, $alph_len);
        $ptrn_list .= html->li( _ptrn_to_str($ptrn, $alph) );
    }
    $ptrn_list = html->ol( $ptrn_list . html->li('...') );

    my $alph_text = (join ', ', @$alph);
    $self->{text} =
        "Все $ptrn_len-буквенные слова, составленные из букв $alph_text, записаны" .
        " в алфавитном порядке.<br/>Вот начало списка: $ptrn_list Запишите слово," .
        " которое стоит на <strong>$pos-м месте</strong> от начала списка."
}

sub morse {
    my($self) = @_;
    my $first = rnd->in_range(2, 6);
    my $second = rnd->in_range($first + 1, 10);

    $self->{text} = <<QUESTION
Азбука Морзе позволяет кодировать символы для сообщений по радиосвязи, задавая комбинацию точек и тире.
Сколько различных символов (цифр, букв, знаков пунктуации и т.д.) можно закодировать,
используя код азбуки Морзе длиной не менее $first и не более $second сигналов (точек и тире)?
QUESTION
;
    my $answer = 0;
    $answer += 2 ** $_ for $first..$second;
    $self->{correct} = $answer;
}

sub log_base {
    my ($base,  $value) = @_;
    return log($value)/log($base);
}

sub bulbs{
    my($self) = @_;
    my $quantity = rnd->in_range(3, 100); 

    $self->{text} =
        "Световое табло состоит из лампочек. Каждая лампочка может находиться в одном из трех состояний 
        («включено», «выключено» или «мигает»). Какое наименьшее количество лампочек должно находиться 
        на табло, чтобы с его помощью можно было передать $quantity различных сигналов?",

    $self->{correct} = ceil(log_base(3, $quantity));
}

1;

__END__
