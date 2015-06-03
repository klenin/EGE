# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B07;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Russian::Names;
use EGE::NumText qw(num_by_words);

use POSIX qw(ceil);
use Data::Dumper;

sub positive_stmt {
    my ($p, $me) = (shift, shift);
    return 'никто не разбил' unless (@_);
    my $stmt = rnd->pick(
        [ ('это') x 3 ],
        [ 'это сделал', 'это сделала', 'это сделали' ],
        [ 'виноват', 'виновата', 'виноваты' ],
        [ ('всему виной') x 3 ]);
    my $s = $stmt->[@_ > 1 ? 2 : $p->[$_[0]]->{gender}];
    ucfirst($s) . ' ' . join ' или ',
      map { $_ == $me ? 'я' : $p->[$_]->{name} } @_;
}

sub negative_stmt {
    my ($p, $me) = (shift, shift);
    return 'разбил директор' unless @_;
    my $neg = rnd->pick(
        [ 'не виноват', 'не виновата', 'не виновны' ],
        [ 'этого не делал', 'этого не делала', 'этого не делали' ],
        [ 'не разбивал', 'не разбивала', 'не разбивали' ]);
    my $s = @_ > 1 ?
      join ', ', map { $_ == $me ? 'ни я' : "ни $p->[$_]->{name}" } @_ :
        $_[0] == $me ? 'я' : $p->[$_[0]]->{name};
    ucfirst($s) . ' ' . $neg->[@_ > 1 ? 2 : $p->[$_[0]]->{gender}];
}

sub make_powers {
    # придумать подходящее для задачи распределение: много к границам, мало
    # к середине, при этом нет нулей или $n
    my ($n) = @_;
    my $ans_pow = rnd->in_range(1, $n-1);
    my $ans_index = rnd->in_range(0, $n - 1);
    my @powers = map { rnd->in_range(0, $n - 3) } 0 .. $n - 1;
    @powers = map { $_ >= $ans_pow ? $_ + 2 : $_ + 1 } @powers;
    $powers[$ans_index] = $ans_pow;
    \@powers;
}

sub make_stmts {
    my ($n) = @_;
    my $row_powers = make_powers($n);

    
    my $ans = {};
    for my $i (0 .. $n-1) {
        my @select = rnd->pick_n($row_powers->[$i], 0 .. $n-1);
        $ans->{$i}{$_} = 1 for @select;
    }
    my @col_powers = ((0) x $n);
    for my $i (0 .. $n-1) {
        for my $j (0 .. $n-1) {
            ++$col_powers[$j] if $ans->{$i}{$j};
        }
    }
    my %pow_col;
    for my $i (0 .. $n - 1) {
        $pow_col{$col_powers[$i]} ||= [];
        push @{$pow_col{$col_powers[$i]}}, $i;
    }
    my ($min, $mi) = ($n + 1, -1);
    for my $pow (keys %pow_col) {
        if (@{$pow_col{$pow}} < $min) {
            ($min, $mi) = (scalar @{$pow_col{$pow}}, $pow);
        }
    }
    # если нет столбца с уникальной степенью - добавляем новую строку
    # и в ней ставим единички так, чтобы появился столбец с уникальной ст-ю
    my @elems = rnd->shuffle(@{$pow_col{$mi}});
    my $ans_index = shift @elems;
    if (@elems) {
        $ans->{$n}->{$_} = 1 for @elems;
        ++$n;
    }
    ($n, $col_powers[$ans_index], $ans_index, $ans);
}

sub who_is_right {
    my ($self) = @_;
    my $n = rnd->in_range(7, 9);
    my @people = EGE::Russian::Names::different_names($n + 1);

    my ($ans_pow, $ans_index, $stmts);
    ($n, $ans_pow, $ans_index, $stmts) = make_stmts($n);

    for my $i (0 .. $n - 1) {
        my $s;
        my %h = %{$stmts->{$i}};
        if (keys %h <= ceil($n/2)) {
            $s = positive_stmt(\@people, $i, keys %h);
        } else {
            $s = negative_stmt(\@people, $i, grep { !$h{$_} } 0 .. $n - 1);
        }
        $self->{text} .= "$people[$i]->{name}: «$s»<br/>";
    }

    my $action = rnd->pick(
        [ 'разбил окно', 'в кабинете' ],
        [ 'разбил цветочный горшок', 'в кабинете' ],
        [ 'разбил мензурки', 'в лаборатории' ],
        [ 'разбил люстру', 'в учительской' ] );
    my $big_men = rnd->pick(
        [ 'директору', 'директора' ],
        [ 'завучу', 'завуча' ],
        [ 'классному руководителю', 'руководителя' ],
        [ 'участковому', 'участкового' ]);

    $self->{text} = ucfirst(num_by_words($n)) .
      ' школьников, остававшихся в классе на перемене, были вызваны ' .
      "к $big_men->[0]. <strong>Один из них</strong> " .
      join(' ', @$action) . '. На вопрос ' .
      "$big_men->[1], кто это сделал, были получены следующие ответы:<br/>" .
      "<p>$self->{text}</p>" .
      "Кто $action->[0], если известно, что из этих " .
      num_by_words($n, '', 'genitive') . " высказываний " .
      ($ans_pow == 1 ? 'истино' : 'истины') .
      ' <strong>только ' . num_by_words($ans_pow, 2) . '</strong>' .
      '? Ответ запишите в виде первой буквы имени.';

    $self->{correct} = substr($people[$ans_index]->{name}, 0, 1);
}

1;
