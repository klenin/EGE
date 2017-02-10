# Copyright © 2017 Vadim D. Kirpa
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::EGE::Z11;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog qw(make_block);
use EGE::LangTable;

sub gen_branches_sum {
    my ($n, $branches) = @_;
    my $cur_oper = $branches->[$n];
    return $cur_oper if $n == 0;
    [ '+', gen_branches_sum($n - 1, $branches), $cur_oper ];
}

sub gen_text_block {
    my %args = @_;
    make_block([
        'func', [ 'F', $args{param} ], [
            '=', 'F', $args{value},
            'if', [ $args{sign}, $args{param}, $args{threshold} ], [
                '=', 'F', $args{branches_sum}
            ]
        ]
    ]);
}

sub gen_eval_block {
    my %args = @_;
    my $code_block = gen_text_block(@_);
    EGE::Prog::add_statement($code_block, [ '=', 'M', [ '()', 'F', $args{start} ] ]);
}

sub gen_text_print_block {
    my %args = @_;;
    make_block([
        'func', [ 'F', $args{param} ], [
            'expr', [ 'print', $args{print_type}, $args{value} ],
            'if', [ $args{sign}, $args{param}, $args{threshold} ], [
                @{$args{branches_call}}
            ]
        ]
    ]);
}

sub gen_eval_print_block {
    my %args = @_;;
    make_block([
        'func', [ 'F', $args{param} ], [
            '=', 'F', 0,
            'if', [ $args{sign}, $args{param}, $args{threshold} ], [
                '=', 'F', $args{branches_sum}
            ],
            '=', 'F', [ '+', 'F', $args{ret} ]
        ],
        '=', 'M', [ '()', 'F', $args{start} ]
    ]);
}

sub recursive_alg {
    my ($self) = @_;
    my $param = rnd->index_var;
    my $alg = rnd->pick(
        { sign => '>', op => '-', threshold => rnd->in_range(1, 3), start => rnd->in_range(4, 7) },
        { sign => '<', op => '+', threshold => 7 - rnd->in_range(1, 3), start => 7 - rnd->in_range(3, 6) }
    );
    my $task = rnd->pick(
        {
            val => $param, ret => $param,
            text => 'Че­му бу­дет рав­на сум­ма всех чи­сел, на­пе­ча­тан­ных на экра­не при вы­пол­не­нии вы­зо­ва',
            gen_text_block => \&gen_text_print_block, gen_eval_block => \&gen_eval_print_block, print_type => 'num' },
        {
            val => '*', ret => '1',
            text => 'Сколь­ко сим­во­лов «звёздоч­ка» будет на­пе­ча­та­но на экра­не при вы­пол­не­нии вы­зо­ва',
            gen_text_block => \&gen_text_print_block, gen_eval_block => \&gen_eval_print_block, print_type => 'str' },
        {
            val => rnd->in_range(2, 5),
            text => 'Че­му бу­дет рав­но зна­че­ние, вы­чис­лен­ное ал­го­рит­мом при вы­пол­не­нии вы­зо­ва',
            gen_text_block => \&gen_text_block, gen_eval_block => \&gen_eval_block }
    );
    my @steps = map rnd->in_range(1, 3), 1 .. rnd->in_range(2, 3);
    my @branches = map [ '()', 'F', [ $alg->{op}, $param, $_ ] ], @steps;
    my @branches_call;
    unshift @branches_call, $_ and unshift @branches_call, 'expr' for @branches;
    my $branches_sum = gen_branches_sum($#branches, \@branches);
    my @args = (
        param => $param, value => $task->{val}, sign => $alg->{sign},
        threshold => $alg->{threshold}, branches_call => \@branches_call,
        branches_sum => $branches_sum, ret => $task->{ret}, start => $alg->{start},
        print_type => $task->{print_type} );
    $self->{text} =
        'Ниже на че­ты­рех язы­ках про­грам­ми­ро­ва­ния за­пи­сан ре­кур­сив­ный ал­го­ритм F ' .
        EGE::LangTable::table($task->{gen_text_block}->(@args), [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C' ] ]) .
        $task->{text} . " F($alg->{start})";

    my $code_block = $task->{gen_eval_block}->(@args);
    $self->{correct} = $code_block->run_val('M');
    $self->{accept} = qr/^-?\d+$/;
}
1;
