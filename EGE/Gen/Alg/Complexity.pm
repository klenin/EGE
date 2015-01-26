# Copyright © 2010-2011 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::Complexity;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::LangTable;

use constant MIN_COUNT => 4;
use constant MAX_COUNT => 6;
use constant MAX_DEGREE => 3;


sub pow {
    my ($var, $degree) = @_;
    if ($degree > 1) {
        ['*', $var, pow($var, --$degree)]
    }
    elsif ($degree == 1) {
        $var
    }
    else {
        rnd->const_value
    }
}

sub final_expr {
    my $iter = $_[0];
    ('expr', ['print', [map $iter->{$_} ? $_ : (), keys $iter]]);
}

sub get_var {
    my $var = rnd->index_var;
    $var .= rnd->index_var while (defined $_[0]->{$var});
    $var;
}

sub cycle {
    my ($count, $is_it_iterator) = @_;
    $_[0]-- or return final_expr($is_it_iterator);

    if (List::Util::sum(values $is_it_iterator) > 1 and rnd->coin) {
        my @if_vars = rnd->pick_n(2, map $is_it_iterator->{$_} ? $_ : (), keys $is_it_iterator);
        return ('if', ['==', @if_vars], [cycle($_[0], $is_it_iterator)]);   
    }
    
    my @ret = ();
    my $var = get_var $is_it_iterator;  
    while (rnd->coin) {
        push @ret, ('=', $var, pow(rnd->pick(keys $is_it_iterator), rnd->in_range(0, MAX_DEGREE)));
        $is_it_iterator->{$var} = 0;
        $var = get_var $is_it_iterator;
    }
    push @ret, 'for', $var, 0, pow(rnd->pick(keys $is_it_iterator), rnd->in_range(0, MAX_DEGREE));
    $is_it_iterator->{$var} = 1;
    my $c = rnd->coin;
    push @ret, $c? [cycle($_[0], $is_it_iterator)] : [ final_expr($is_it_iterator) ];
    $is_it_iterator->{$var} = 0;
    
    !$c and $_[0] and @ret = (@ret, cycle($_[0], $is_it_iterator));
    return @ret;
}

sub cycles_complexity 
{
    my ($self) = @_;    
    my $main_var = rnd->pick(qw(N M K));
    my ($count, $block);
    my @mistakes_names = qw(var_as_const ignore_if change_min); 
    $self->{correct} = 0;
    
    
    while(1) {
        $count = rnd->in_range(MIN_COUNT, MAX_COUNT);
        $block = EGE::Prog::make_block([cycle($count, {$main_var => 0})]);

        my @indexes = rnd->shuffle(1..7);
        my @variants = $block->complexity({$main_var => 1});
        MISTAKE:
        while (@indexes) {
            my $i = shift @indexes;
            my %mistakes = map(($mistakes_names[$_] => $i/2**$_ % 2), (0..@mistakes_names-1));
            $mistakes{var_as_const} and $mistakes{var_as_const} = $main_var;

            my $cur_variant = $block->complexity({$main_var => 1}, \%mistakes);
            $cur_variant == $_ and next MISTAKE for (@variants);
            push @variants, $cur_variant;
            if (@variants == 4) {
                my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);   
                $self->{text} = "Асимптотическая сложность следующего алгоритма равна: $lt";
                $self->variants(map "O($main_var <sup>" . $_ . "</sup>)", @variants) and return;
            }
            
        } 

    }
}
1;
