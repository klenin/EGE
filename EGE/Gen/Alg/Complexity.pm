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

use EGE::Prog;
use EGE::Random;
use EGE::Utils;

sub elem { # ax^y
    my ($x, $a, $y) = @_;
    return $a if $y == 0;
    my $p = $y == 1 ? $x : [ '**', $x, $y ];
    $a == 1 ? $p : [ '*', $a, $p ];
}

sub to_logic { EGE::Prog::make_expr($_[0])->to_lang_named('Logic') }
sub big_o { "<i>O</i>($_[0])" }

sub o_poly {
    my ($self) = @_;
    my $max_power = rnd->in_range(3, 5);
    my $max_coeff = rnd->in_range(2, 7);
    my @powers = sort { $b <=> $a } rnd->pick_n(4, 0 .. 6);
    my @coeffs = map rnd->in_range(1, 9), 1 .. 4;
    my @elems = map elem('n', @$_), rnd->shuffle(@{EGE::Utils::transpose \@coeffs, \@powers});
    my $func = to_logic(List::Util::reduce { [ '+', $a, $b ] } @elems);
    $self->{text} ="Функция $func является";
    $self->variants(map big_o(to_logic($_)),
        map(elem('n', 1, $_), grep $_ > 0, @powers), List::Util::max(@coeffs));
}

sub o_poly_cmp {
    my ($self) = @_;
    my $power = rnd->in_range(3, 6);
    my ($func, @variants) = map big_o(to_logic(elem 'n', 1, $_)),
        $power, $power + 1, $power - 1, [ '/', 1, $power ], 0, -$power;
    $self->{text} ="Всякая функция, являющаяся $func, является также и";
    $self->variants(@variants);
}

use constant MAX_DEGREE => 2;

sub pow {
    my ($var, $degree) = @_;
    my $ret = $var;
    $ret = [ '*', $var, $ret ] while --$degree;
    $ret;
}

sub cycle_complexity
{
    my ($self) = @_;
    $self->{correct} = 0;

    my $main_var = rnd->pick(qw(x y z));
    my @vars = rnd->index_var(3);
    my @degrees = rnd->shuffle(1 .. MAX_DEGREE);
    @degrees = @degrees[ 1 .. 3 ];
    my $cycles = [
        'for', $vars[0], 0, pow($main_var, $degrees[0]), [
            'for', $vars[1], 0, pow($main_var, $degrees[1]), [
                '=', [ '[]', 'buf', $vars[1] ], $vars[1]
            ],
            'for', $vars[2], 0, pow($main_var, $degrees[2]), [
                '=', [ '[]', 'buf', $vars[2] ], $vars[2]
            ]
        ]
    ];
    my $block = EGE::Prog::make_block($cycles);
    my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
    $self->{text} = "Определите асимптотическую сложность следующего алгоритма: $lt";
    my @variants = ( $block->complexity($main_var),
        $degrees[0] + List::Util::min(@degrees[ 1 .. 2 ]),
        List::Util::sum(@degrees),
        $degrees[0] );
    $self->variants(map big_o(to_logic([ '**', $main_var, $_ ])), @variants);
}

use constant COUNTER => 0;

sub final_expr {
    my $iter = $_[0];
    ('expr', [ 'print', map $iter->{$_} ? $_ : (), keys $iter ]);
}

sub new_var {
    my $var = rnd->index_var;
    $var .= rnd->index_var while (defined $_[0]->{$var});
    $_[0]->{$var} = $_[1];
    $var;
}

sub rnd_pow {
    my ($other_counts, $is_it_iterator, $assign, $create_new_var, $use_iter) = @_;
    my @vars = keys $is_it_iterator;
    !$use_iter and @vars = grep { !$is_it_iterator->{$_} } @vars;
    my $var = rnd->pick(@vars);
    if ($create_new_var && $other_counts->{assign} && rnd->coin) {
        $other_counts->{assign}--;
        my $right = rnd_pow($other_counts, $is_it_iterator, $assign, 0, $use_iter);
        $var = new_var($is_it_iterator, 0);
        push $assign, '=', $var, $right;
    }
    pow($var, rnd->in_range(1, MAX_DEGREE)); 
}

sub rnd_poly {
    my $poly = rnd_pow(@_);
    $poly = [ '+', $poly, rnd_pow(@_) ] while (rnd->coin);
    $poly = [ '+', $poly, rnd->const_value ] if rnd->coin;
    $poly;
}

use constant P_IF_EQ => 0.3;
use constant P_IF_LESS => 0.3;

sub make_cycle {
    my ($for_count, $other_counts, $is_it_iterator) = @_;
    if ($for_count) {

        my $assign = [];
        my $children = [];
        my @head;
        my $iter;
        if (rnd->coin(P_IF_EQ) && List::Util::sum(values $is_it_iterator) > 1 && $other_counts->{if}) {
            $other_counts->{if}--;
            my @if_vars = rnd->pick_n(2, map $is_it_iterator->{$_} ? $_ : (), keys $is_it_iterator); 
            $is_it_iterator->{$iter = $if_vars[0]} = 0;
            @head = ('if', [ '==', @if_vars ]);
        }
        elsif (rnd->coin(P_IF_LESS) && List::Util::sum(values $is_it_iterator) > 0 && $other_counts->{if}) {
            $other_counts->{if}--;
            my $var = rnd->pick(grep { $is_it_iterator->{$_} } keys $is_it_iterator);
            my $old_val = delete $is_it_iterator->{$var};
            my $expr = rnd_pow($other_counts, $is_it_iterator, $assign, 0, 0);
            $is_it_iterator->{$var} = $old_val;
            @head = ('if', rnd->coin ? [ '<=', $var, $expr] : [ '>=', $expr, $var]);
        }
        else {
            $for_count--;
            my $e = rnd_pow($other_counts, $is_it_iterator, $assign, 1, 1);
            $iter = new_var($is_it_iterator, 1);
            @head = ('for', $iter, 0, $e);
            push $children, '=', 'counter', [ '+', 'counter', 1 ];
        }

        my $next_for_count;
        do {
            $for_count -= $next_for_count = $for_count ? rnd->in_range(1, $for_count) : 0;
            push $children, make_cycle($next_for_count, $other_counts, $is_it_iterator);
        } while ($for_count);     
        
        $iter and $is_it_iterator->{$iter} ^= 1; 
        return @$assign, @head, $children;

    }
    else {
        return final_expr($is_it_iterator);        
    }

}

use constant MIN_FOR => 2;
use constant MAX_FOR => 3;
use constant MAX_IF => 2;
use constant MAX_ASSIGN => 2;

sub complexity
{
    my ($self) = @_;    
    my $main_var = rnd->pick(qw(x y z));
    my @mistakes_names = qw(var_as_const ignore_if_eq change_min ignore_if_less); 
    $self->{correct} = 0;

    while(1) {
        my $cycle = [ '=', 'counter', 0, make_cycle(
            rnd->in_range(MIN_FOR, MAX_FOR), 
            { if => MAX_IF, assign => MAX_ASSIGN }, 
            { $main_var => 0 }) ];
        
        my $block = EGE::Prog::make_block($cycle);
        my @indexes = rnd->shuffle(1 .. 7);
        my @variants = $block->complexity({ $main_var => 1 });
        MISTAKE:
        while (@indexes) {
            my $i = shift @indexes;
            my %mistakes = map(($mistakes_names[$_] => $i/2**$_ % 2), (0 .. @mistakes_names - 1));
            $mistakes{var_as_const} and $mistakes{var_as_const} = $main_var;

            my $cur_variant = $block->complexity({ $main_var => 1 }, \%mistakes);
            $cur_variant == $_ and next MISTAKE for @variants;
            push @variants, $cur_variant;
            if (@variants == 4) {
                if (rnd->coin && List::Util::max(@variants) == $variants[0]) { 
                    pop @variants;
                    next MISTAKE;
                }
                my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);   
                $self->{text} = "Определите асимптотическую сложность следующего алгоритма: $lt";
                if (COUNTER) {
                    unshift($cycle, '=', $main_var, 10);
                    $self->{text} .= EGE::Prog::make_block($cycle)->run_val('counter');
                }
                $self->variants(map big_o(to_logic([ '**', $main_var, $_ ])), @variants);
                return;
            }
            
        } 

    }
}




1;
