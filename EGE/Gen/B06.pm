# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B06;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Russian::Names;
use EGE::Russian::Jobs;
use Data::Dumper;

use Storable qw(dclone);
use Switch;

sub all_perm {
    my $rec;
    $rec = sub {
        my ($curr_res, $tot_res, @elems) = @_;
        unless (@elems) {
            push @{$tot_res}, $curr_res;
            return;
        }
        for my $i (0 .. $#elems) {
            $rec->([@$curr_res, $elems[$i]], $tot_res,
                     (@elems[0 .. $i - 1], @elems[$i + 1 .. $#elems]));
        }
    };
    my $res = [];
    $rec->([], $res, @_);
    $res;
}

sub push_each {
    my ($arr, $val) = @_;
    push @$_, $val for @$arr;
};

sub unique_pairs {
    my ($n) = @_;
    my @res;
    for my $i (0 .. $n - 1) {
        for my $j ($i + 1 .. $n - 1) {
            push @res, [$i, $j];
        }
    }
    @res;
}

sub all_pairs {
    my ($n) = @_;
    my @res;
    for my $i (0 .. $n - 1) {
        for my $j (0 .. $n - 1) {
            push @res, [$i, $j];
        }
    }
    @res;
}

sub AddRelation {
    my ($i, $j, $h, $sym) = @_;
    $h->{$i}{$j} = 1;
    $h->{$j}{$i} = 1 if $sym;
}

sub RmRelation {
    my ($i, $j, $h, $sym) = @_;
    delete $h->{$i}{$j};
    delete $h->{$j}{$i} if $sym;
}

#(правее какой вершины)
my $p = { 0 => {}, 1 => {}, 2 => {}, 3 => {} };
#together
my $t = { 0 => {}, 1 => {}, 2 => {}, 3 => {} };
#not together
my $n = { 0 => {}, 1 => {}, 2 => {}, 3 => {} };
# ссылки на нижний уровень (левее каких позиций)
my $d_left = { 0 => {}, 1 => {}, 2 => {}, 3 => {} };
#(правее каких позиций)
my $d_right = { 0 => {}, 1 => {}, 2 => {}, 3 => {} };
#на каком месте
my $d_t = { 0 => {}, 1 => {}, 2 => {}, 3 => {} };
#не на каком месте
my $d_n = { 0 => {}, 1 => {}, 2 => {}, 3 => {} };

# [контейнер, симметричное ли отношение]
my @relations = ( [$p, 0], [$t, 1], [$n, 1], [$d_left, 0], [$d_right, 0],
                  [$d_t, 0], [$d_n, 0] );

# Все варианты сделать топологическую сортировку учитывая ограничения "правее"
# Изначально была идея написать такую процедуру, которая учитывает все
# ограничения. Идея провалилась, но её происки далее просматриваются в коде.
sub all_top {
    our $ans = [];

    my $rec;
    $rec = sub {
        my ($path, $results, $n) = @_;
        unless ($n) {
            push @$ans, $_ for @$results;
        }
        my @to_go = grep { !@{$path->{$_}} } keys %{$path};
        for my $i (@to_go) {
            my $nr = dclone($results);
            my $np = dclone($path);
            push_each($nr, $i);
            delete $np->{$i};
            while (my ($k, $v) = each %{$np}) {
                $np->{$k} = [ grep { $_ != $i } @$v ];
            }
            $rec->($np, $nr, $n - 1);
        }
    };

    my %h = map { $_ => [keys %{$p->{$_}}] } 0 .. 3;
    $rec->(\%h, [[]], 4);

    %h = map { (join ' ', @{$_} ) => $_ } @$ans; # unique ans
    map { $h{$_} } sort keys %h;
}

sub check {
    my ($r) = @_;
    for my $i (0 .. $#{$r}) {
        my ($pred, $curr, $nxt) = @{$r}[$i-1 .. $i+1];
        for (keys %{$t->{$curr}}) {
            unless (($i > 0 && $t->{$curr}{$pred}) ||
                ($i < $#{$r} && $t->{$curr}{$nxt})) {
                return 0;
            }
        }
        if ($i > 0 && $n->{$curr}{$pred} ||
            $i < $#{$r} && $n->{$curr}{$nxt}) {
            return 0;
        }
        for (keys %{$d_left->{$curr}}) {
            return 0 if $_ <= $i;
        }
        for (keys %{$d_right->{$curr}}) {
            return 0 if $_ >= $i;
        }
        for (keys %{$d_t->{$curr}}) {
            return 0 if $_ != $i;
        }
        for (keys %{$d_n->{$curr}}) {
            return 0 if $_ == $i;
        }
    }
    1;
}

sub filter { # не учитывется ограничения "правее"
    my ($r, $t, $n) = @_;
    grep { check($_, $t, $n) } @$r;
}

sub total_check {
    my ($r) = @_;
    my %pos = map { $r->[$_] => $_ } 0 .. 3;
    for my $i (0 .. $#{$r}) {
        my ($curr) = $r->[$i];
        for (keys %{$p->{$curr}}) {
            return 0 if $i <= $pos{$_};
        }
    }
    1;
}

sub total_filter { # учитываются все ограничения
    my ($r, $t, $n) = @_;
    grep { total_check($_, $t, $n) && check($_, $t, $n) } @$r;
}

sub try_new_cond {
    my ($action, $answers) = @_;
    AddRelation(@$action);
    my @new_ans = filter( $answers );
    if (@new_ans == @$answers || !@new_ans) {
        RmRelation(@$action);
    } else {
        @$answers = @new_ans;
    }
    return @new_ans == 1;
}

sub create_cond {
    our (@relations) = @_;
    sub make_pairs {
        my @pairs;
        for my $rel (@relations) {
            my @tmp = $rel->[1] ? unique_pairs(4) : all_pairs(4);
            push @pairs, [@$_, @$rel] for @tmp;
        }
        rnd->shuffle(@pairs);
    }
    my @pairs = make_pairs();
    my @answers = all_top();
    my $ok = !@answers;
    while (!$ok) {
        $ok |= try_new_cond(pop @pairs, \@answers);
        @pairs = make_pairs unless @pairs;
    }
    clear_cond();
    @{$answers[0]};
}

sub create_init_cond { # создать ограничения "правее"
    my ($cnt) = @_;
    my @edgees = rnd->pick_n($cnt, unique_pairs(4) );
    for (@edgees) {
        my ($i, $j) = @$_;
        $p->{$j}{$i} = 1;
    }
}

sub clear_cond {
    my $var = all_perm(0 .. 3);
    my $ans_cnt = total_filter($var);
    my $ok = 1;
    while ($ok) {
        $ok = 0;
        for my $rel (@relations) {
            for my $i (0 .. 3) {
                for my $j (keys %{$rel->[0]->{$i}}) {
                    RmRelation($i, $j, @$rel);
                    if (total_filter($var) != $ans_cnt) {
                        AddRelation($i, $j, @$rel)
                    } else {
                        $ok = 1;
                    }
                }
            }
        }
    }
}

sub create_questions {
    my ($descr) = @_;
    my @cond;
    for my $j (0 .. $#relations) {
        my $rel = $relations[$j];
        for my $i (0 .. 3) {
            for (keys %{$rel->[0]->{$i}}) {
                if (!$rel->[1] || $i > $_) {
                    push @cond, $descr->[$j]->($i, $_)
                }
            }
        }
    }
    @cond;
}

sub genitive { # родительный падеж
    my $name = shift;
    switch ($name) {
        case /й$/ { $name =~ s/й$/я/ }
        case /ь$/ { $name =~ s/ь$/я/ }
        else { $name .= 'а' };
    }
    $name;
}

sub ablative { # творительный падеж
    my $name = shift;
    switch ($name) {
        case /й$/ { $name =~ s/й$/ем/ }
        case /ь$/ { $name =~ s/ь$/ем/ }
        else { $name .= 'ом' };
    }
    $name;
}

sub on_right {
    switch (rnd->in_range(0, 3)) {
        case 0 { return "$_[1] живет левее  " . genitive($_[0]) }
        case 1 { return "$_[0] живёт правее " . genitive($_[1]) }
        case 2 { return "$_[1] живет левее, чем  " . $_[0] }
        case 3 { return "$_[0] живёт правее, чем " . $_[1] }
    }
 }

sub together {
    "$_[0] живёт рядом " . "c " . ablative($_[1]);
}

sub not_together {
    "$_[0] живёт не рядом " . "c " . ablative($_[1]);
}

sub solve {
    my ($self) = @_;
    my @names = EGE::Russian::Names::different_males(4);
    my @prof = EGE::Russian::Jobs::different_jobes(4);

    create_init_cond(rnd->pick(2, 2, 3));
    my @prof_order = create_cond(@relations[1 .. 2]);

    my @descr = ( sub { on_right($prof[$_[0]], $prof[$_[1]]) },
                  sub { together($prof[$_[0]], $prof[$_[1]]) },
                  sub { not_together($prof[$_[0]], $prof[$_[1]]) } );
    my @cond = create_questions(\@descr);

    for my $r ($t, $p, $n) { $r->{$_} = {} for (0 .. 3) } #clear conditions
    create_init_cond(rnd->pick(2, 2, 3));
    my @ans = create_cond(@relations[1 .. $#relations]);

    @descr = ( sub { on_right($names[$_[0]], $names[$_[1]]) },
               sub { together($names[$_[0]], $names[$_[1]]) },
               sub { not_together($names[$_[0]], $names[$_[1]]) },
               sub { on_right($prof[$prof_order[$_[1]]], $names[$_[0]]) },
               sub { on_right($names[$_[0]], $prof[$prof_order[$_[1]]]) },
               sub { "$names[$_[0]] работает " .
                       ablative($prof[$prof_order[$_[1]]]) },
               sub { "$names[$_[0]] не работает " .
                       ablative($prof[$prof_order[$_[1]]]) } );
    @cond = (@cond, create_questions(\@descr));

    $self->{text} =
      "На одной улице стоят в ряд 4 дома, в которых живут 4 человека: " .
      (join ", ", map "<strong>$_</strong>", @names) .
      ". Известно, что каждый из них владеет ровно одной из следующих профессий: " .
      (join ", ", map "<strong>$_</strong>", @prof) .
      ", но неизвестно, кто какой и неизвестно, кто в каком доме живет. Однако, " .
      "известно, что:<br/>";

    $self->{text} .= "<ol>";
    $self->{text} .= "<li>$_</li>" for rnd->shuffle(@cond);
    $self->{text} .= "</ol>";

    my @example = rnd->shuffle(@names);
    $self->{text} .=
      "Выясните, кто какой профессии, и кто где живет, и дайте ответ в виде " .
      "заглавных букв имени людей, в порядке слева направо. Например, если бы " .
      "в домах жили (слева направо) " . (join ", ", @example) .
      ", ответ был бы: " . join '', map substr($_, 0, 1), @example;

    $self->{correct} = join '',  map { substr($names[$_], 0, 1) } @ans;
}
