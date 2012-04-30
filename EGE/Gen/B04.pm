# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B04;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use List::Util qw(sum first);

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

sub _lex_order_validate {
    my ($ptr, $alph, $pos) = @_;
    my $new_p = [(0) x @$ptr];
    _next_ptrn_lex($new_p, int(@$alph)) for 1 .. $pos - 1; #since already 1st pos
    $a = join '', @$new_p;
    $b = join '', @$ptr;
    die "$a != $b" unless $a eq $b ;
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
    _lex_order_validate($ptrn, $alph, $pos);

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

1;
