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

#path (правее какой вершины)
my $p = [ [], [], [], [] ];
#together
my $t = [ [], [], [], [] ];
#not together
my $n = [ [], [], [], [] ];
# ссылки на нижний уровень (левее каких позиций)
my $d_left = [ [], [], [], [] ];
#(правее каких позиций)
my $d_right = [ [], [], [], [] ];
#вместе
my $d_t = [ [], [], [], [] ];
#не вместе
my $d_n = [ [], [], [], [] ];

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

    my %h = map { $_ => $$p[$_] } 0 .. $#{$p};
    rec(\%h, [[]], scalar @{$p});

    %h = map { (join ' ', @{$_} ) => $_ } @$ans; # unique ans
    map { $h{$_} } sort keys %h;
}

sub filter {
    my ($r, $t, $n) = @_;
    grep { check($_, $t, $n) } @$r;
}

sub check {
    my ($r) = @_;
    for my $i (0 .. $#{$r}) {
        for (@{$t->[$r->[$i]]}) {
            unless (($i > 0 && $r->[$i - 1] == $_) ||
                ($i < $#{$r} && $r->[$i + 1] == $_)) {
                return 0;
            }
        }
        for (@{$n->[$r->[$i]]}) {
            if (($i > 0 && $r->[$i - 1] == $_) ||
                    ($i < $#{$r} && $r->[$i + 1] == $_)) {
                return 0;
            }
        }
        for (@{$d_left->[$r->[$i]]}) {
            return 0 if $_ <= $i;
        }
        for (@{$d_right->[$r->[$i]]}) {
            return 0 if $_ >= $i;
        }
        for (@{$d_t->[$r->[$i]]}) {
            return 0 if $_ != $i;
        }
        for (@{$d_n->[$r->[$i]]}) {
            return 0 if $_ == $i;
        }
    }
    1;
}

sub all_pairs {
    my ($n) = @_;
    my @res;
    for my $i (0 .. $n - 1) {
        for my $j ($i + 1 .. $n - 1) {
            push @res, [$i, $j];
        }
    }
    @res;
}

sub try_new_cond {
    my ($pair, $answers) = @_;
    our ($variant, $i, $j) = @$pair;

    sub MakeBiAction {
        my ($arr) = @_;
        {
            try => sub { push @{$arr->[$j]}, $i; push @{$arr->[$i]}, $j },
            restore => sub { pop @{$arr->[$j]}; pop @{$arr->[$i]} }
        }
    }
    sub MakeMonoAction {
        my ($arr) = @_;
        {
            try => sub { push @{$arr->[$i]}, $j },
            restore => sub { pop @{$arr->[$i]} }
        }
    }

    my $action =
      [
       MakeBiAction($t),
       MakeBiAction($n),
       MakeMonoAction($d_left),
       MakeMonoAction($d_right),
       MakeMonoAction($d_t),
       MakeMonoAction($d_n)
      ]->[$variant];
    $action->{try}->();
    my @new_ans = filter([ all_top() ]);  #filter( $answers );
    my $new_cnt = @new_ans;
    if ($new_cnt == @$answers || !$new_cnt) {
        $action->{restore}->();
        return 0;
    }
    @$answers = @new_ans;
    return $new_cnt == 1;
}

sub create_cond {
    our ($max_act) = @_;
    sub make_pairs {
        my @pairs;
        for my $p (all_pairs(scalar @$p)) {
            for my $variant (0 .. $max_act) {
                push @pairs, [$variant, @$p];
            }
        }
        if ($max_act >= 4) {
            for (0 .. scalar @$p) {
                push @pairs, [4, $_, $_];
            }
        }
        rnd->shuffle(@pairs);
    }
    my @pairs = make_pairs();
    my $ok = 0;
    my @answers = all_top();
    my $ans_cnt = @answers;
    while (!$ok) {
        $ok |= try_new_cond(pop @pairs, \@answers);
        @pairs = make_pairs unless @pairs;
    }
    \@answers;
}

sub create_init_cond {
    my ($cnt) = @_;
    my @edgees = rnd->shuffle( all_pairs(scalar @$p) );
    for (@edgees[0 .. $cnt - 1]) {
        my ($i, $j) = @$_;
        push @{$p->[$i]}, $j;
    }
}

sub clear { #todo - удалить лишние условия (подумать будут ли они заодно)
    my $var = all_perm();
    my $ok = 1;
  LOOP:
    while ($ok) {
        $ok = 0;
        for my $i (0 .. $#{$t}) {
            for (0 .. $#{$t->[$i]}) {
                my $e = shift @{$t->[$i]};
                $t->[$e] = [ map { $_ != $i } @{$t->[$e]} ];
                if (scalar( filter($var) ) != 1) {
                    push @{$t->[$i]}, $e;
                    push @{$t->[$e]}, $i;
                } else {
                    redo LOOP;
                }
            }
        }
    }
}

sub solve {
    my ($self) = @_;
    #print Dumper( (all_pairs(4))[0..3] );
    my @names = qw/ A B C D /;
    my @prof = qw/ 0 1 2 3 4 /;

    create_init_cond(rnd->pick(2, 2, 3));
    #$p->[0] = [1];
    #$p->[2] = [3];
    my $ans = create_cond(1);
    #clear();
=begin
    $self->{text} .= "<pre>";
    $self->{text} .= Dumper filter([all_top()]);
    $self->{text} .= "</pre>";
=cut

    my @cond;
    for my $i (0 .. $#{$p}) {
        for (@{$p->[$i]}) {
            push @cond, "$prof[$i] правее $prof[$_]";
        }
    }
    for my $i (0 .. $#{$t}) {
        for (@{$t->[$i]}) {
            push @cond, "$prof[$i] рядом $prof[$_]" if ($i > $_);
        }
    }
    for my $i (0 .. $#{$n}) {
        for (@{$n->[$i]}) {
            push @cond, "$prof[$i] не рядом $prof[$_]" if ($i > $_);
        }
    }

    @cond = ();
    $_ = [ [], [], [], [] ] for $p, $t, $n, $d_left, $d_right, $d_t, $d_n;

#    $p->[0] = [1];
#    $p->[2] = [3];
#    $d_t->[1] = [0];
#    $d_right->[0] = [2];


    create_init_cond(rnd->pick(2, 2, 3));
    $ans = create_cond(5);

    for my $i (0 .. $#{$p}) {
        for (@{$p->[$i]}) {
            push @cond, "$names[$i] правее $names[$_]";
        }
    }
    for my $i (0 .. $#{$t}) {
        for (@{$t->[$i]}) {
            push @cond, "$names[$i] рядом $names[$_]" if ($i > $_);
        }
    }
    for my $i (0 .. $#{$n}) {
        for (@{$n->[$i]}) {
            push @cond, "$names[$i] не рядом $names[$_]" if ($i > $_);
        }
    }
    for my $i (0 .. $#{$d_t}) {
        for (@{$d_t->[$i]}) {
            push @cond, "$names[$i] работает $prof[$_]";
        }
    }
    for my $i (0 .. $#{$d_n}) {
        for (@{$d_n->[$i]}) {
            push @cond, "$names[$i] не является $prof[$_]";
        }
    }
    for my $i (0 .. $#{$d_left}) {
        for (@{$d_left->[$i]}) {
            push @cond, "$names[$i] левее $prof[$_]";
        }
    }
    for my $i (0 .. $#{$d_right}) {
        for (@{$d_right->[$i]}) {
            push @cond, "$names[$i] правее $prof[$_]";
        }
    }
    #todo добавить стрелочки на нижний уровень "рядом" "нерядом"

    $self->{text} .= "<ol>";
    $self->{text} .= "<li>$_</li>" for @cond;
    $self->{text} .= "</ol>";
#=begin
    $self->{text} .= "<pre>";
    #    $self->{text} .= Dumper [all_top()];
    for (filter([all_top()])) {
        $self->{text} .= join '', @$_;
        $self->{text} .= "<br/>";
    }
    $self->{text} .= Dumper $p, $t, $n, $d_t, $d_n, $d_left, $d_right;
    $self->{text} .= "</pre>";
#=cut

    #    print scalar all_top($p, $n), "\n";

#    print scalar filter([ all_top($p, $n) ]), "\n";
    #print scalar all_top($p, $n), "\n";
    #print Dumper all_top($p, $n);
    $self->{correct} = Dumper $ans;
}
