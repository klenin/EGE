# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B07;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Russian::Names;
use EGE::NumText qw/ num_by_words /;

use POSIX qw/ ceil /;
use Data::Dumper;

# хак для того, чтобы Dumper не экранировал символы строк из
# других модулей перед выводом
$Data::Dumper::Useqq = 1;
{ no warnings 'redefine';
    sub Data::Dumper::qquote {
        my $s = shift;
        return "'$s'";
    }
}

sub positive_stmt {
    my ($p, $me) = (shift, shift);
    return "никто не разбил" unless (@_);
    my $stmt = rnd->pick([("это") x 3],
                         ["это сделал", "это сделала", "это сделали"],
                         ["виноват", "виновата", "виноваты"],
                         [("всему виной") x 3]);
    my $s = $stmt->[@_ > 1 ? 2 : $p->[$_[0]]->[1]];
    ucfirst($s) . ' ' . join " или ",
      map { $_ == $me ? "я" : $p->[$_]->[0] } @_;
}

sub negative_stmt {
    my ($p, $me) = (shift, shift);
    return "разбил директор" unless (@_);
    my $neg = rnd->pick(["не виноват", "не виновата", "не виновны"],
                        ["этого не делал", "этого не делала", "этого не делали"],
                        ["не разбивал", "не разбивала", "не разбивали"]);
    my $s = (@_ > 1) ?
      join ", ", map { $_ == $me ? "ни я" : "ни $p->[$_]->[0]" } @_ :
        $_[0] == $me ? "я" : $p->[$_[0]]->[0];
    ucfirst($s) . " " . $neg->[@_ > 1 ? 2 : $p->[$_[0]]->[1]];
}

sub different_people {
    my ($count) = @_;
    my %h = map { $_, [] } 'А' .. 'Я';
    push @{$h{substr($_, 0, 1)}}, [$_, 0] for @EGE::Russian::Names::male;
    push @{$h{substr($_, 0, 1)}}, [$_, 1] for @EGE::Russian::Names::female;
    map { rnd->pick(@{$h{$_}}) } rnd->pick_n($count, keys %h);
}

sub make_stmts {
    my ($n) = @_;
    my $row_powers = (make_powers($n));
    my $ans = {};
    for my $i (0 .. $n) {
        my @select = rnd->pick_n($row_powers->[$i], 0 .. $n-1);
        $ans->{$i}->{$_} = 1 for @select;
    }
    my @col_powers = ((0) x $n);
    for my $i (0 .. $n-1) {
        for my $j (0 .. $n-1) {
            ++$col_powers[$j] if $ans->{$i}{$j};
        }
    }
    my %col_powers;
    for my $i (0 .. $n-1) {
        $col_powers{$col_powers[$i]} ||= [];
        push @{$col_powers{$col_powers[$i]}}, $i;
    }
    my ($min, $mi) = ($n + 1, -1);
    for my $pow (keys %col_powers) {
        if (@{$col_powers{$pow}} < $min) {
            ($min, $mi) = (scalar @{$col_powers{$pow}}, $pow);
        }
    }
    my $ans_index = $mi;
    if (@{$col_powers{$mi}} > 1) {
        my @elems = rnd->shuffle(@{$col_powers{$mi}});
        $ans_index = shift @elems;
        $ans->{$n}->{$_} = 1 for @elems;
        ++$n;
    }

    ($n, $col_powers[$ans_index], $ans_index, $ans);
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

sub print_matr { # debug
    my ($a, $n) = @_;
    my $res = "<style>td { border : 1px solid black } </style>";
    $res .= "<table style=\"border: 1px solid black; border-collapse: collapse\">";
    $res .= "<tr><td></td>";
    $res .= "<th>$_</th>" for 0 .. $n-1;
    for my $i (0 .. $n-1) {
        $res .= "<tr><th>$i</th>";
        for my $j (0 .. $n-1) {
            $res .= "<td>" .
              ($a->{$i}->{$j} ? 1 : "-" ) .
              "</td>";
        }
        $res .= "<tr>";
    }
    "$res</table>";
}

sub who_is_right {
    my ($self) = @_;
    my $n = rnd->in_range(7, 9);
    my @people = different_people($n + 1);

    my ($ans_pow, $ans_index, $stmts);
    ($n, $ans_pow, $ans_index, $stmts) = make_stmts($n);
#    $self->{text} .= print_matr($stmts, $n);

    for my $i (0 .. $n - 1) {
        my $s;
        my %h = %{$stmts->{$i}};
        if (keys %h <= ceil($n/2)) {
            $s = positive_stmt(\@people, $i, keys %h);
        } else {
            $s = negative_stmt(\@people, $i, grep { !$h{$_} } 0 .. $n - 1);
        }
        $self->{text} .= "$people[$i]->[0]: «$s»<br/>";
    }

    my $action = rnd->pick( ["разбил окно", "в кабинете"],
                            ["разбил цветочный горшок", "в кабинете"],
                            ["разбил мензурки", "в лаборатории"],
                            ["разбил люстру", "в учительской"] );
    my $big_men = rnd->pick( ["директору", "директора"],
                             ["завучу", "завуча"],
                             ["классному руководителю", "руководителя"],
                             ["участковому", "участкового"] );
    $self->{text} = ucfirst(num_by_words($n)) .
      " школьников, остававшихся в классе на перемене, были вызваны " .
      "к $big_men->[0]. <strong>Один из них</strong> " .
      (join " ", @$action) . ". На вопрос " .
      "$big_men->[1], кто это сделал, были получены следующие ответы:<br/>" .
      "<p>$self->{text}</p>" .
      "Кто $action->[0], если известно, что из этих девяти высказываний " .
      ($ans_pow == 1 ? "истино" : "истины") .
      " <strong>только " . num_by_words($ans_pow, 2) . "</strong>" .
      "? Ответ запишите в виде первой буквы имени.";

    $self->{correct} = substr($people[$ans_index]->[0], 0, 1);
}

1;
