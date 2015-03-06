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
use EGE::Alg;

sub elem { # ax^y
    my ($x, $a, $y) = @_;
    return $a if $y == 0;
    my $p = $y == 1 ? $x : [ '**', $x, $y ];
    $a == 1 ? $p : [ '*', $a, $p ];
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
        $power, $power + 1, $power - 1, [ '/', 1, $power ], 0, -$power;
    $self->{text} ="Всякая функция, являющаяся $func, является также и";
    $self->variants(@variants);
}

sub cycle_complexity
{
    my ($self) = @_;
    $self->{correct} = 0;

    my $main_var = rnd->pick(qw(n m));
    my @vars = rnd->index_var(3);
    my @degrees = rnd->shuffle(1 .. 5);
    my $cycles = [
        'for', $vars[0], 0, EGE::Alg::pow($main_var, $degrees[0]), [
            'for', $vars[1], 0, EGE::Alg::pow($main_var, $degrees[1]), [
                '=', [ '[]', 'buf', $vars[1] ], $vars[1]
            ],
            'for', $vars[2], 0, EGE::Alg::pow($main_var, $degrees[2]), [
                '=', [ '[]', 'buf', $vars[2] ], $vars[2]
            ]
        ]
    ];
    my $block = EGE::Prog::make_block($cycles);
    my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
    $self->{text} = "Определите асимптотическую сложность следующего алгоритма: $lt";
    my @variants = ( $block->complexity({ $main_var => 1 }),
        $degrees[0] + List::Util::min(@degrees[ 1 .. 2 ]),
        List::Util::sum(@degrees),
        $degrees[0] );
    $self->variants(map EGE::Alg::big_o(EGE::Alg::to_logic([ '**', $main_var, $_ ])), @variants);
}

use constant MAKE_COUNTER => 0;

sub complexity
{
    my ($self) = @_;    
    my $main_var = rnd->pick(qw(m n));
    my @mistakes_names = qw(var_as_const ignore_if_eq change_min ignore_if_less);
    my $max_counts = {
        if => 4,
        assign => 4,
    };
    my $for_count = rnd->in_range(4, 6);

    while(1) {
        my $vars = { all => { $main_var => 1 }, iterator => {}, if => {} };
        my $cycle = [ EGE::Alg::make_rnd_block($for_count, $max_counts, $vars) ];
        MAKE_COUNTER and unshift $cycle, '=', 'counter', 0; 
        
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
                $self->{correct} = 0;
                $self->{text} = "Определите асимптотическую сложность следующего алгоритма: $lt";
                if (MAKE_COUNTER) {
                    unshift($cycle, '=', $main_var, 10);
                    $self->{text} .= EGE::Prog::make_block($cycle)->run_val('counter');
                }
                $self->variants(map EGE::Alg::big_o(EGE::Alg::to_logic([ '**', $main_var, $_ ])), @variants);
                return;
            }
        } 
    }
}

sub substitution
{
    my ($self) = @_;
    my $main_var = rnd->pick(qw(n m));
    my $mask = 'XXXXX';
    while (1) {
	    my $max_counts = {
	        if => 2,
	        assign => 2,
	        subs => $mask,
	    };
	    my $for_count = rnd->in_range(4, 6);
	    my $vars = { all => { $main_var => 1 }, iterator => {}, if => {} };
	    my $code = [ EGE::Alg::make_rnd_block($for_count, $max_counts, $vars) ];
	    my $subs = $max_counts->{subs};
	    if (ref $subs eq 'ARRAY') {
	    	my $lt = EGE::LangTable::table(EGE::Prog::make_block($code), 
	    		[ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
	    	my %variants;
	    	my $slot = [];
	    	EGE::Alg::swap($code, $mask, $slot);
	    	for (@$subs) {
	    		for my $i (0 .. 2) { $slot->[$i] = $_->[$i]; }
	    		my $cur = EGE::Prog::make_block($code)->complexity({ $main_var => 1 });
	    		$variants{$cur} = $_ if !$variants{$cur};
	    		if (keys %variants >= 4) {
	    			$self->{correct} = 0;
	    			$self->variants(map EGE::Alg::to_logic($_), values %variants);
	    			$self->{text} = "На какое выражение следует заменить $mask, чтобы сложность алгоритма составила " .
                    EGE::Alg::big_o(EGE::Alg::to_logic([ '**', $main_var, (keys %variants)[0]])) . $lt;
					return;
	    		}
	    	}
	    }
    }
}

1;
