# Copyright © 2015 Alexander S. Klenin
# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::Complexity;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use List::Util;

use EGE::Alg;
use EGE::LangTable;
use EGE::Prog;
use EGE::Random;
use EGE::Utils;

sub elem { # ax^y
    my ($x, $a, $y) = @_;
    return $a if $y eq '0';
    my $p = $y eq '1' ? $x : [ '**', $x, $y ];
    $a eq '1' ? $p : [ '*', $a, $p ];
}

sub _log {
    [ '()', 'log', $_[0] ]
}

sub o_poly {
    my ($self) = @_;
    my $max_power = rnd->in_range(3, 5);
    my $max_coeff = rnd->in_range(2, 7);
    my @powers = sort { $b <=> $a } rnd->pick_n(4, 0 .. 6);
    my @coeffs = map rnd->in_range(1, 9), 1 .. 4;
    my @elems = map elem('n', @$_), rnd->shuffle(@{EGE::Utils::transpose \@coeffs, \@powers});
    my $func = EGE::Alg::to_logic(List::Util::reduce { [ '+', $a, $b ] } @elems);
    $self->{text} ="Функция $func является";
    $self->variants(map EGE::Alg::big_o(EGE::Alg::to_logic($_)),
        map(elem('n', 1, $_), grep $_ > 0, @powers), List::Util::max(@coeffs));
}

sub o_poly_cmp {
    my ($self) = @_;
    my $power = rnd->in_range(3, 6);
    my ($func, @variants) = map EGE::Alg::big_o(EGE::Alg::to_logic(elem 'n', 1, $_)),
        $power, $power - rnd->in_range(1, 3), [ '/', 1, $power ], -$power;
    push @variants, map EGE::Alg::big_o(EGE::Alg::to_logic($_)), 
        elem('n', _log('n'), $power - rnd->in_range(1, 2)),
        _log(elem 'n', 1, $power),
        [ '+', _log('n'), elem 'n', 1, $power - rnd->in_range(1, 3) ];
    my $correct = rnd->pick(map EGE::Alg::big_o(EGE::Alg::to_logic($_)),
        elem('n', 1, $power + rnd->in_range(1, 3)),
        elem($power, 1, 'n'),
        elem($power - 1, 1, 'n'),
        elem('n', _log('n'), $power + rnd->in_range(0, 2)),
    );
    $self->{text} ="Всякая функция, являющаяся $func, является также и";
    $self->variants($correct, rnd->pick_n(3, @variants));
}

use constant MAKE_COUNTER => 0;

sub complexity {
    my ($self) = @_;    
    my $n = rnd->pick(qw(m n));
    my @mistakes_names = qw(var_as_const ignore_if_eq change_min ignore_if_less ignore_if_mod);
    my $max_counts = {
        if => 4,
        assign => 4,
        rand => 0,
    };
    my $for_count = rnd->in_range(4, 6);

    while(1) {
        my $vars = { all => { $n => 1 }, iterator => {}, if => {} };
        my $cycle = [ EGE::Alg::make_rnd_block($for_count, $max_counts, $vars) ];
        MAKE_COUNTER and unshift @$cycle, '=', 'counter', 0; 
        
        my $block = EGE::Prog::make_block($cycle);        
        my @indexes = rnd->shuffle(1 .. 7);
        my @variants = $block->complexity({ $n => 1 });
        MISTAKE:
        while (@indexes) {
            my $i = shift @indexes;
            my %mistakes = map(($mistakes_names[$_] => $i/2**$_ % 2), (0 .. @mistakes_names - 1));
            $mistakes{var_as_const} and $mistakes{var_as_const} = $n;

            my $cur_variant = $block->complexity({ $n => 1 }, \%mistakes);
            $cur_variant == $_ and next MISTAKE for @variants;
            push @variants, $cur_variant;
            if (@variants == 4) {
                if (rnd->coin && List::Util::max(@variants) == $variants[0]) { 
                    pop @variants;
                    next MISTAKE;
                }
                my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);   
                $self->{text} = "Определите асимптотическую сложность следующего алгоритма: $lt";
                if (MAKE_COUNTER) {
                    unshift @$cycle, '=', $n, 10;
                    $self->{text} .= EGE::Prog::make_block($cycle)->run_val('counter');
                }
                $self->variants(map EGE::Alg::big_theta(EGE::Alg::to_logic([ '**', $n, $_ ])), @variants);
                return;
            }
        } 
    }
}

sub substitution {
    my ($self) = @_;
    my $n = rnd->pick(qw(n m));
    my $mask = 'XXXXX';
    while (1) {
        my $other_counts = {
            if => 2,
            assign => 2,
            subs => $mask,
            rand => 0,
        };
        my $for_count = rnd->in_range(4, 6);
        my $vars = { all => { $n => 1 }, iterator => {}, if => {} };
        my $code = [ EGE::Alg::make_rnd_block($for_count, $other_counts, $vars) ];
        my $subs = $other_counts->{subs};
        if (ref $subs eq 'ARRAY') {
            my $slot = shift @$subs;
            my $lt = EGE::LangTable::table(EGE::Prog::make_block($code), 
                [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
            my %variants;

            for (@$subs) {
                for my $i (0 .. 2) { $slot->[$i] = $_->[$i]; }
                my $cur = EGE::Prog::make_block($code)->complexity({ $n => 1 });
                $variants{$cur} ||= $_;
                if (keys %variants >= 4) {
                    $self->variants(map EGE::Alg::to_logic($_), values %variants);
                    $self->{text} =
                        "Дан алгоритм $lt Чтобы сложность этого алгоритма составляла " .
                        EGE::Alg::big_theta(EGE::Alg::to_logic([ '**', $n, (keys %variants)[0]])) .
                        ", строку $mask следует заменить на выражение" ;
                    return;
                }
            }
        }
    }
}

sub amortized {
    my ($self) = @_;
    my $n = rnd->pick(qw(n m));
    my @ij = qw(i j);
    while (1) {
        my $other_counts = {
            if => 0,
            assign => 3,
            rand => 0,
        };

        my $iters = { map(($_, rnd->in_range(1, 3)), @ij) };
        my $vars = {
            all => { $n => 1, %$iters },
            iterator => $iters,
            if => {}
        };
        my ($cond, @used_vars) = EGE::Alg::make_rnd_cond($vars);
        $vars->{if}->{$_} = 1 for @used_vars;
        my $fst = [
            EGE::Alg::make_rnd_block(rnd->in_range(1, 2), $other_counts, $vars)
        ];
        my $sec = [
            'if', $cond,
            [ EGE::Alg::make_rnd_block(rnd->in_range(1, 2), $other_counts, $vars) ] 
        ];
        my $env = { $n => 1 };
        my @comp = map EGE::Prog::make_block($_)->complexity($env, {}, $iters), ($fst, $sec);

        if ($comp[0] == $comp[1]) {
            my $b = EGE::Prog::make_block([
                'for', 'i', 0, EGE::Alg::pow($n, $iters->{i}), [
                    'for', 'j', 0, EGE::Alg::pow($n, $iters->{j}), [
                        @$fst, @$sec
                    ]
                ]
            ]);
            my $ans = $b->complexity({ $n => 1 });
            my $v = {
                $ans => 1,
                $b->complexity({ $n => 1 }, { map(($_, 1), qw(ignore_if_eq ignore_if_less ignore_if_mod)) } ) => 1,
                $comp[0] => 1,
                $iters->{i} + $iters->{j} => 1,
                $iters->{i} => 1,
                $iters->{j} => 1,
            };
            my @variants = keys %$v;

            if (@variants >= 4) {
                my $lt = EGE::LangTable::table($b, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
                $variants[$_] == $ans and ($variants[$_], $variants[0]) = ($variants[0], $variants[$_]) for 0 .. @variants - 1;    
                $self->{text} = "Определите асимптотическую сложность следующего алгоритма: $lt";
                $self->variants(map EGE::Alg::big_theta(EGE::Alg::to_logic([ '**', $n, $_ ])), @variants[0 .. 3]);
                return;
            }
        }
    }
}

package EGE::Gen::Alg::Complexity::ComplexityDI;
use base 'EGE::GenBase::DirectInput';

use EGE::Prog;
use EGE::Random;

sub cycle_complexity {
    my ($self) = @_;

    my $n = rnd->pick(qw(n m));
    my @vars = rnd->index_var(3);
    my @degrees = rnd->shuffle(1 .. 5);
    my $cycles = [
        'for', $vars[0], 0, EGE::Alg::pow($n, $degrees[0]), [
            'for', $vars[1], 0, EGE::Alg::pow($n, $degrees[1]), [
                '=', [ '[]', 'buf', $vars[1] ], $vars[1]
            ],
            'for', $vars[2], 0, EGE::Alg::pow($n, $degrees[2]), [
                '=', [ '[]', 'buf', $vars[2] ], $vars[2]
            ]
        ]
    ];
    my $block = EGE::Prog::make_block($cycles);
    my $pow_n_x = EGE::Alg::big_theta(EGE::Alg::to_logic([ '**', $n, 'x' ]));
    my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
    $self->{text} = "Асимптотическую сложность следующего алгоритма равна $pow_n_x: $lt Чему равно x?";
    $self->accept_number();
    $self->{correct} = $block->complexity({ $n => 1 });
}

1;
