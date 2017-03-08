# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B06;
use base 'EGE::GenBase::DirectInput';
use v5.10;

use strict;
use warnings;
use utf8;

use EGE::Html;
use EGE::Random;
use EGE::Russian::Names;
use EGE::Russian::Jobs;
use EGE::Prog;

use Data::Dumper;

use Storable qw(dclone);

my %relations = ( ToRight     => { v => {}, is_sym => 0 },
                  Together    => { v => {}, is_sym => 1 },
                  NotTogether => { v => {}, is_sym => 1 },
                  PosLeft     => { v => {}, is_sym => 0 },
                  PosRight    => { v => {}, is_sym => 0 },
                  Pos         => { v => {}, is_sym => 0 },
                  NotPos      => { v => {}, is_sym => 0 } );

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

sub relation_clear_all {
    for (keys %relations) {
        $relations{$_}->{v} = { 0 => {}, 1 => {}, 2 => {}, 3 => {} };
    }
}

sub relation_add {
    my ($i, $j, $r) = @_;
    $relations{$r}->{v}->{$i}{$j} = 1;
    $relations{$r}->{v}->{$j}{$i} = 1 if $relations{$r}->{is_sym};
}

sub relation_rm {
    my ($i, $j, $r) = @_;
    delete $relations{$r}->{v}->{$i}{$j};
    delete $relations{$r}->{v}->{$j}{$i} if $relations{$r}->{is_sym};
}

sub check {
    my ($c) = @_;
    my %pos = map { $c->[$_] => $_ } 0 .. 3;
    for my $i (0 .. $#{$c}) {
        my $curr = $c->[$i];
        for (keys %{$relations{Together}->{v}{$curr}}) {
            return 0 unless abs($pos{$_} - $i) == 1
        }
        for (keys %{$relations{NotTogether}->{v}{$curr}}) {
            return 0 if abs($pos{$_} - $i) == 1
        }
        for (keys %{$relations{ToRight}->{v}{$curr}}) {
            return 0 if $i <= $pos{$_};
        }
        for (keys %{$relations{PosLeft}->{v}{$curr}}) {
            return 0 if $_ <= $i;
        }
        for (keys %{$relations{PosRight}->{v}{$curr}}) {
            return 0 if $_ >= $i;
        }
        for (keys %{$relations{Pos}->{v}{$curr}}) {
            return 0 if $_ != $i;
        }
        for (keys %{$relations{NotPos}->{v}{$curr}}) {
            return 0 if $_ == $i;
        }
    }
    1;
}

sub filter {
    my ($perm) = @_;
    grep { check($_) } @$perm;
}

sub try_new_cond {
    my ($cond, $answers) = @_;
    return if $relations{$cond->[2]}->{v}{$cond->[0]}{$cond->[1]};
    relation_add(@$cond);
    my @new_ans = filter($answers);
    if (@new_ans == @$answers || !@new_ans) {
        relation_rm(@$cond);
    } else {
        @$answers = @new_ans;
    }
    return @new_ans == 1;
}

sub create_init_cond {
    # создать ограничения "правее": важно, чтобы не было циклов
    my ($cnt) = @_;
    relation_clear_all();
    my @edges = rnd->pick_n($cnt, unique_pairs(4) );
    for (@edges) {
        my ($i, $j) = @$_;
        $relations{ToRight}->{v}->{$j}{$i} = 1;
    }
}

sub create_cond {
    our (@relations) = @_;
    sub make_pairs {
        my @pairs;
        for my $rel (@relations) {
            my @tmp = $relations{$rel}->{is_sym} ?
                          unique_pairs(4) : all_pairs(4);
            push @pairs, [@$_, $rel] for @tmp;
        }
        rnd->shuffle(@pairs);
    }
    my @pairs = make_pairs();
    my @answers;
    do {
        create_init_cond(rnd->pick(2, 2, 3));
        @answers = filter( all_perm(0 .. 3) );
    } while (@answers == 0);
    while (@answers != 1) {
        try_new_cond(pop @pairs, \@answers);
        @pairs = make_pairs unless @pairs;
    }
    clear_cond();
    @{$answers[0]};
}

sub clear_cond {
    my $var = all_perm(0 .. 3);
    my $ans_orig = filter($var);
    my $ok = 1;
    while ($ok) {
        $ok = 0;
        for my $rel (keys %relations) {
            for my $i (0 .. 3) {
                for my $j (keys %{$relations{$rel}->{v}->{$i}}) {
                    relation_rm($i, $j, $rel);
                    if (filter($var) != $ans_orig) {
                        relation_add($i, $j, $rel);
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
    for my $key (keys %relations) {
        my $rel = $relations{$key};
        for my $i (keys %{$rel->{v}}) {
            for my $j (keys %{$rel->{v}->{$i}}) {
                if (!$rel->{is_sym} || $i > $j) {
                    push @cond, $descr->{$key}->($i, $j)
                }
            }
        }
    }
    @cond;
}

sub on_right {
    rnd->pick(
        sub { "$_[1] живет левее " . EGE::Russian::Names::genitive($_[0]) },
        sub { "$_[0] живёт правее " . EGE::Russian::Names::genitive($_[1]) },
        sub { "$_[1] живет левее, чем $_[0]" },
        sub { "$_[0] живёт правее, чем $_[1]" },
    )->(@_);
}

sub together {
    "$_[0] живёт рядом c " . EGE::Russian::Names::ablative($_[1]);
}

sub not_together {
    "$_[0] живёт не рядом c " . EGE::Russian::Names::ablative($_[1]);
}

sub solve {
    my ($self) = @_;
    my @names = EGE::Russian::Names::different_males(4);
    my @prof = EGE::Russian::Jobs::different_jobs(4);

    my @prof_order = create_cond('Together', 'NotTogether');

    my %descr = (
        ToRight => sub { on_right($prof[$_[0]], $prof[$_[1]]) },
        Together => sub { together($prof[$_[0]], $prof[$_[1]]) },
        NotTogether => sub { not_together($prof[$_[0]], $prof[$_[1]]) }
    );
    my @questions = create_questions(\%descr);

    my @ans = create_cond(keys %relations);

    %descr = (
        ToRight => sub { on_right($names[$_[0]], $names[$_[1]]) },
        Together => sub { together($names[$_[0]], $names[$_[1]]) },
        NotTogether => sub { not_together($names[$_[0]], $names[$_[1]]) },
        PosLeft => sub { on_right($prof[$prof_order[$_[1]]], $names[$_[0]]) },
        PosRight => sub { on_right($names[$_[0]], $prof[$prof_order[$_[1]]]) },
        Pos => sub { "$names[$_[0]] работает " .
                     EGE::Russian::Names::ablative($prof[$prof_order[$_[1]]]) },
        NotPos => sub { "$names[$_[0]] не работает " .
                        EGE::Russian::Names::ablative($prof[$prof_order[$_[1]]]) }
    );
    @questions = (@questions, create_questions(\%descr));

    $self->{text} =
      'На одной улице стоят в ряд 4 дома, в которых живут 4 человека: ' .
      (join ', ', map html->tag('strong', $_), @names) .
      '. Известно, что каждый из них владеет ровно одной из следующих профессий: ' .
      (join ', ', map html->tag('strong', $_), @prof) .
      ', но неизвестно, кто какой и неизвестно, кто в каком доме живет. Однако, ' .
      'известно, что: ' . html->ol_li([ rnd->shuffle(@questions) ]);

    my @example = rnd->shuffle(@names);
    $self->{text} .=
      'Выясните, кто какой профессии, и кто где живет, и дайте ответ в виде ' .
      'заглавных букв имени людей, в порядке слева направо. Например, если бы ' .
      'в домах жили (слева направо) ' . (join ', ', @example) .
      ', ответ был бы: ' . join '', map substr($_, 0, 1), @example;

    $self->{correct} = join '',  map substr($names[$_], 0, 1), @ans;
}

sub _rec_calculate {
    my ($f_v, $s_v, $f_n, $s_n, $n) = @_;
    my $func;
    for (my $i = 2; $i <= $n; $i++) {
      $func = $s_v * $f_n + $f_v * $s_n;
      $f_v = $s_v;
      $s_v = $func
    }
    $func;
}

sub recursive_function {
    my ($self) = @_;
    my $first_num = rnd->in_range(2, 6);
    my $second_num = rnd->in_range_except(2, 6, $first_num);
    my $first_val = rnd->in_range(0, 5);
    my $second_val = rnd->in_range(1, 5);
    my $n = rnd->in_range(4, 7);

    my @exprs = (
        [ '==', [ '()', 'F', 0 ], $first_val ],
        [ '==', [ '()', 'F', 1 ], $second_val ],
        [ '==',
            [ '()', 'F', 'n' ],
                [ '+',
                    [ '*', [ '()', 'F', [ '-', 'n', 1 ] ], $first_num ],
                    [ '*', [ '()', 'F', [ '-', 'n', 2 ] ], $second_num ] ]
        ],
        [ '()', 'F', 'n' ],
        [ '>=', 'n', 2 ],
        [ '()', 'F', 'n' ],
    );

    my @texts = map EGE::Prog::make_expr($_)->to_lang_named('Logic', { html => 1 }), @exprs;

    $self->{text} =
        "Алгоритм вычисления значения функции $texts[3], где <i>n</i> — натуральное число, " .
        'задан следующими соотношениями:' .
        html->ul_li(
            [ "$texts[0], $texts[1]", "$texts[2], при $texts[4]" ],
            { html->style(list_style_type => 'none') }) .
        " Чему равно значение функции $texts[5]? В ответе запишите только натуральное число.";

    $self->{correct} = _rec_calculate($first_val, $second_val, $first_num, $second_num, $n);
    $self->accept_number;
}

1;
