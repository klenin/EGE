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

use EGE::LangTable;
use EGE::Prog;
use EGE::Random;
use EGE::Utils;
use EGE::Bits;

use EGE::Prog::RandomAlg qw(to_logic big_o big_theta monomial _log);

sub o_poly {
    my ($self) = @_;
    my $max_power = rnd->in_range(3, 5);
    my $max_coeff = rnd->in_range(2, 7);
    my @powers = sort { $b <=> $a } rnd->pick_n(4, 0 .. 6);
    my @coeffs = map rnd->in_range(1, 9), 1 .. 4;
    my @elems = map monomial('n', @$_), rnd->shuffle(@{EGE::Utils::transpose \@coeffs, \@powers});
    my $func = to_logic(List::Util::reduce { [ '+', $a, $b ] } @elems);
    $self->{text} ="Функция $func является";
    $self->variants(map big_o($_),
        map(monomial('n', 1, $_), grep $_ > 0, @powers), List::Util::max(@coeffs));
}

sub o_poly_cmp {
    my ($self) = @_;
    my $power = rnd->in_range(3, 6);
    my ($func, @variants) = map big_o(monomial 'n', 1, $_),
        $power, $power - rnd->in_range(1, 3), [ '/', 1, $power ], -$power;
    push @variants, map big_o($_),
        monomial('n', _log('n'), $power - rnd->in_range(1, 2)),
        _log(monomial 'n', 1, $power),
        [ '+', _log('n'), monomial 'n', 1, $power - rnd->in_range(1, 3) ];
    my $correct = rnd->pick(map big_o($_),
        monomial('n', 1, $power + rnd->in_range(1, 3)),
        monomial($power, 1, 'n'),
        monomial($power - 1, 1, 'n'),
        monomial('n', _log('n'), $power + rnd->in_range(0, 2)),
    );
    $self->{text} ="Всякая функция, являющаяся $func, является также и";
    $self->variants($correct, rnd->pick_n(3, @variants));
}

sub complexity {
    my ($self) = @_;
    my $n = 'n';
    my @mistakes_names = qw(var_as_const ignore_if_eqignore_if_less ignore_if_mod change_min change_sum);
    my $for_count = 3;          # не использовать числа меньше 4, не сгенерируется из-за маленького количество дистракторов

    while(1) {
        my $other_counts = {
            if => 3,
            assign => 2,
            counter => 0,           # 1 чтобы вставить счётчик для отладки
        };
        my $vars = { all => { $n => 1 }, iterator => {}, if => {} };
        my $code = [ EGE::Prog::RandomAlg::rnd_block($for_count, $other_counts, $vars) ];
        unshift @$code, '=', $n, 10, '=', 'counter', 0
            if $other_counts->{counter};
        $code = EGE::Prog::make_block($code);
        my %variants;
        $variants{$code->complexity({ $n => 1 })} = 1;

        my $index = EGE::Bits->new;
        my $s = @mistakes_names - 1;
        $index->set_size($s);
        MISTAKE: for my $i (rnd->shuffle(1 .. 2 ** $s - 1)) {
            $index->set_dec($i);
            my $mistakes = { map { $mistakes_names[$_] => $index->get_bit($_) } (0 .. $s) };
            $mistakes->{var_as_const} and $mistakes->{var_as_const} = $n;

            my $cur_variant = $code->complexity({ $n => 1 }, $mistakes);
            $variants{$cur_variant} = 0;

            if (keys %variants == 4) {
                delete $variants{$cur_variant} or next MISTAKE
                    if rnd->coin && $variants{List::Util::max(keys %variants)};

                my $lt = EGE::LangTable::table($code, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
                $self->{text} = "Определите асимптотическую сложность следующего алгоритма: $lt";
                $self->{text} .= EGE::Prog::make_block($code)->run_val('counter')
                    if ($other_counts->{counter});
                my @v = keys %variants;
                $self->{correct} = grep $variants{$v[$_]}, 0 .. @v - 1;
                $self->variants(map big_theta([ '**', $n, $_ ]), @v);
                return;
            }
        }
    }
}

sub substitution {
    my ($self) = @_;
    my $n = 'n';
    my $mask = 'XXXXX';
    my $for_count = 3;

    while (1) {
        my $other_counts = {
            if => 2,
            assign => 2,
            subs => $mask,
        };
        my $vars = { all => { $n => 1 }, iterator => {}, if => {} };
        my $code = [ EGE::Prog::RandomAlg::rnd_block($for_count, $other_counts, $vars) ];
        my $subs = $other_counts->{subs};
        next if ref $subs ne 'ARRAY';

        my $slot = shift @$subs;
        my %variants;

        my $lt = EGE::LangTable::table(EGE::Prog::make_block($code),
            [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
        for (@$subs) {
            for my $i (0 .. 2) { $slot->[$i] = $_->[$i]; }
            my $cur = EGE::Prog::make_block($code)->complexity({ $n => 1 });
            $variants{$cur} ||= $_;
            if (keys %variants >= 4) {
                $self->variants(map to_logic($_), values %variants);
                $self->{text} =
                    "Дан алгоритм $lt Чтобы сложность этого алгоритма составляла " .
                    big_theta([ '**', $n, (keys %variants)[0]]) .
                    ", строку $mask следует заменить на выражение" ;
                return;
            }
        }
    }
}

sub amortized {
    my ($self) = @_;
    my $n = 'n';
    my @ij = qw(i j);
    while (1) {
        my $other_counts = {
            if => 0,
            assign => 3,
        };

        my $iters = { map { $_ => rnd->in_range(1, 3) } @ij };
        my $vars = {
            all => { $n => 1, %$iters },
            iterator => $iters,
            if => {}
        };
        my ($cond, @used_vars) = EGE::Prog::RandomAlg::rnd_cond($vars);
        $vars->{if}->{$_} = 1 for @used_vars;
        my $fst = [
            EGE::Prog::RandomAlg::rnd_block(rnd->in_range(1, 2), $other_counts, $vars)
        ];
        my $sec = [
            'if', $cond,
            [ EGE::Prog::RandomAlg::rnd_block(rnd->in_range(1, 2), $other_counts, $vars) ]
        ];
        my $env = { $n => 1 };
        my @comp = map EGE::Prog::make_block($_)->complexity($env, {}, $iters), ($fst, $sec);

        if ($comp[0] == $comp[1]) {
            my $b = EGE::Prog::make_block([
                'for', 'i', 0, EGE::Prog::RandomAlg::pow($n, $iters->{i}), [
                    'for', 'j', 0, EGE::Prog::RandomAlg::pow($n, $iters->{j}), [
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
                $self->variants(map big_theta([ '**', $n, $_ ]), @variants[0 .. 3]);
                return;
            }
        }
    }
}

package EGE::Gen::Alg::Complexity::ComplexityDI;
use base 'EGE::GenBase::DirectInput';

use EGE::Prog;
use EGE::Random;

use EGE::Prog::RandomAlg qw(big_theta);

sub cycle_complexity {
    my ($self) = @_;
    my $n = rnd->pick(qw(n m));
    my @vars = rnd->index_var(3);
    my @degrees = rnd->shuffle(1 .. 5);
    my $cycles = [
        'for', $vars[0], 0, EGE::Prog::RandomAlg::pow($n, $degrees[0]), [
            'for', $vars[1], 0, EGE::Prog::RandomAlg::pow($n, $degrees[1]), [
                '=', [ '[]', 'buf', $vars[1] ], $vars[1]
            ],
            'for', $vars[2], 0, EGE::Prog::RandomAlg::pow($n, $degrees[2]), [
                '=', [ '[]', 'buf', $vars[2] ], $vars[2]
            ]
        ]
    ];
    my $block = EGE::Prog::make_block($cycles);
    my $pow_n_x = big_theta([ '**', $n, 'x' ]);
    my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
    $self->{text} = "Асимптотическая сложность следующего алгоритма равна $pow_n_x: $lt Чему равно x?";
    $self->accept_number();
    $self->{correct} = $block->complexity({ $n => 1 });
}

1;
