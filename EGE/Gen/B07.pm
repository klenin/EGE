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
    return "разбила Мариванна" unless (@_);
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

sub who_is_right {
    my ($self) = @_;
    my $n = rnd->in_range(4, 6);
    my @people = different_people($n);

    # придумать подходящее для задачи распределение: много к границам, мало
    # к середине
    my $ans_pow = rnd->in_range(1, $n);
    my $ans_index = rnd->in_range(0, $n - 1);
    my @powers = map { rnd->in_range(0, $n - 1) } 0 .. $n - 1;
    @powers = map { $_ >= $ans_pow ? $_ + 1 : $_ } @powers;
    $powers[$ans_index] = $ans_pow;

    my %in_ans;
    my @stmts = map { [] } 1 .. $n;
    for my $i (0 .. $n - 1) {
        for my $j (rnd->pick_n($powers[$i], 0 .. $n - 1)) {
            push @{$stmts[$j]}, $i;
            if ($i == $ans_index) {
                $in_ans{$j} = 1;
            }
        }
    }

    my @strong;
    my @weak;
    for my $i (0 .. $n - 1) {
        if (!@{$stmts[$i]} || @{$stmts[$i]} == $n) {
            push @weak, $i;
            next;
        }
        push @strong, $i;
        my $s;
        my %h = map { $_, 1} @{$stmts[$i]};
        if (@{$stmts[$i]} <= ceil($n/2)) {
            $s = positive_stmt(\@people, $i, keys %h);
        } else {
            $s = negative_stmt(\@people, $i, grep { !$h{$_} } 0 .. $n - 1);
        }
        $self->{text} .= "$people[$i]->[0]: «$s»<br/>";
    }

    for (@weak) {
        my $to = rnd->pick(@strong);
        my $side = rnd->coin();
        $self->{text} .= sprintf("%s: «%s»<br/>",  $people[$_]->[0],
          "$people[$to]->[0] " .
          ["говорит неправду", "говорит правду"]->[$side]);
        push @strong, $_;
        unless ($side xor $in_ans{$to}) { $in_ans{$_} = 1 }
    }

    for (keys %in_ans) {
        $self->{text} .= $people[$_]->[0] . " ";
    }
    $self->{text} = "Ровно " . scalar(keys %in_ans) .
                    " говорят правду: <br/><br/>" . $self->{text};
    $self->{correct} = substr($people[$ans_index]->[0], 0, 1);
}

1;
