# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B06;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use Encode;

use EGE::Random;
use EGE::NumText;
use Data::Dumper;

use Storable qw/ dclone /;

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
    $h->{$i}->{$j} = 1;
    $h->{$j}->{$i} = 1 if $sym;
}

sub RmRelation {
    my ($i, $j, $h, $sym) = @_;
    delete $h->{$i}->{$j};
    delete $h->{$j}->{$i} if $sym;
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

#todo добавить стрелочки на нижний уровень "рядом" "не рядом"

# [container, is_symmetrical]
my @relations = ( [$p, 0], [$t, 1], [$n, 1], [$d_left, 0], [$d_right, 0],
                  [$d_t, 0], [$d_n, 0] );

sub all_top {
    our $ans = [];

    sub rec {
        my ($path, $results, $n) = @_;
        unless ($n) {
            push @$ans, $_ for @$results;
        }
        my @to_go = grep { !@{$path->{$_}} } keys %{$path};
        if (@to_go) {
            for my $i (@to_go) {
                my $nr = dclone($results);
                my $np = dclone($path);
                push_each($nr, $i);
                delete $np->{$i};
                while (my ($k, $v) = each %{$np}) {
                    $np->{$k} = [ grep { $_ != $i } @$v ];
                }
                rec($np, $nr, $n - 1);
            }
        }
    };

    my %h = map { $_ => [keys %{$p->{$_}}] } 0 .. 3;
    rec(\%h, [[]], 4);

    %h = map { (join ' ', @{$_} ) => $_ } @$ans; # unique ans
    map { $h{$_} } sort keys %h;
}

sub check {
    my ($r) = @_;
    for my $i (0 .. $#{$r}) {
        my ($pred, $curr, $nxt) = @{$r}[$i-1 .. $i+1];
        for (keys %{$t->{$curr}}) {
            unless (($i > 0 && $t->{$curr}->{$pred}) ||
                ($i < $#{$r} && $t->{$curr}->{$nxt})) {
                return 0;
            }
        }
        if ($i > 0 && $n->{$curr}->{$pred} ||
            $i < $#{$r} && $n->{$curr}->{$nxt}) {
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

sub filter {
    my ($r, $t, $n) = @_;
    grep { check($_, $t, $n) } @$r;
}

sub cool_check {
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

sub cool_filter {
    my ($r, $t, $n) = @_;
    grep { cool_check($_, $t, $n) && check($_, $t, $n) } @$r;
}

sub try_new_cond {
    my ($action, $answers) = @_;
    AddRelation(@$action);
    my @new_ans = filter([ all_top() ]);  #filter( $answers );
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
    \@answers;
}

sub create_init_cond {
    my ($cnt) = @_;
    my @edgees = rnd->pick_n($cnt, unique_pairs(4) );
    for (@edgees) {
        my ($i, $j) = @$_;
        $p->{$j}->{$i} = 1;
    }
}

sub clear {
    my $var = all_perm(0 .. 3);
    my $ans_cnt = cool_filter($var);
    my $ok = 1;
    while ($ok) {
        $ok = 0;
        for my $rel (@relations) {
            for my $i (0 .. 3) {
                for my $j (keys %{$rel->[0]->{$i}}) {
                    RmRelation($i, $j, @$rel);
                    if (cool_filter($var) != $ans_cnt) {
                        AddRelation($i, $j, @$rel)
                    } else {
                        $ok = 1;
                    }
                }
            }
        }

    }
}

sub solve {
    my ($self) = @_;
    my @names = qw/ A B C D /;
    my @prof = qw/ 0 1 2 3 4 /;

    create_init_cond(rnd->pick(2, 2, 3));
    my $ans = create_cond(@relations[1 .. 2]);
    clear();

    my @descr = ( "правее", "рядом c", "не рядом c" );

    my @cond;
    for my $j (0 .. 2) {
        my $rel = $relations[$j];
        for my $i (0 .. 3) {
            for (keys %{$rel->[0]->{$i}}) {
                if (!$rel->[1] || $i > $_) {
                    push @cond, "$prof[$i] " . $descr[$j] .  " $prof[$_]"
                }
            }
        }
    }

    $self->{text} .= "<ol>";
    $self->{text} .= "<li>$_</li>" for @cond;
    $self->{text} .= "</ol>";

=begin
    $self->{text} .= "<pre>";
    for (filter([all_top()])) {
        $self->{text} .= join '', @$_;
        $self->{text} .= "<br/>";
    }
    $self->{text} .= "----<br/>";
    for (all_top()) {
        $self->{text} .= join '', @$_;
        $self->{text} .= "<br/>";
    }
    $self->{text} .= Dumper $p, $t, $n, $d_t, $d_n, $d_left, $d_right;
    $self->{text} .= "</pre>";
=cut

    $self->{correct} = Dumper $ans;
}
