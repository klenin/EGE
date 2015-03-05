# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Alg;

use strict;
use warnings;

use EGE::Random;
use base 'Exporter';
our @EXPORT_OK = qw(to_logic big_o make_rnd_block);


sub to_logic { EGE::Prog::make_expr($_[0])->to_lang_named('Logic') }
sub big_o { "<i>O</i>($_[0])" }

sub pow { $_[1] == 1 and $_[0] or [ '**', @_ ] }

sub final_expr {
    ('expr', [ 'print', @_ ]);
}

sub new_var {
    my $var = rnd->index_var;
    $var .= rnd->index_var while $_[0]->{$var};
    $_[0]->{$var} = 1;
    $var;
}

use constant MAX_DEGREE => 4;
use constant P_RAND => 0.5;
use constant P_IF => 0.5;
use constant P_ASSIGN => 0.5;

sub rnd_pow {
    my ($vars, $use_iters, $other_counts, $assign) = @_;
    my @all_vars = keys $vars->{all};
    @all_vars = grep !$vars->{iterator}->{$_}, @all_vars if !$use_iters;
    my $var = rnd->pick(@all_vars);
    if ($assign && $other_counts->{assign} && rnd->coin(P_ASSIGN)) {
        $other_counts->{assign}--;
        my $right = rnd_pow($vars, 0, $other_counts);
        $var = new_var($vars->{all});
        push $assign, '=', $var, $right;
    }
    my $degree = rnd->coin(P_RAND) && $other_counts->{rand}-- > 0 ?
        [ '()', 'rand', sort(map &rnd->in_range(1, MAX_DEGREE), 0 .. 1) ] :
        rnd->in_range(1, MAX_DEGREE);
    pow($var, $degree);
    
}

sub rnd_poly {
    my $poly = rnd_pow(@_);
    $poly = [ '+', $poly, rnd_pow(@_) ] while (rnd->coin);
    $poly = [ '+', $poly, rnd->const_value ] if rnd->coin;
    $poly;
}

sub make_rnd_block {
    my ($for_count, $other_counts, $vars) = @_;
    if ($for_count) {
        my $assign = [];
        my $children = [];
        my (@head, @cur_vars, $type);
        if ($other_counts->{if} && rnd->coin(P_IF) && keys($vars->{iterator}) - keys($vars->{if}) >= 2) {
            $type = $vars->{if};
            my $cond;
            my @not_used = grep(!$vars->{if}->{$_}, keys $vars->{iterator});
            if (rnd->coin) {
                @cur_vars = (rnd->shuffle(@not_used))[0 .. 1];
                $cond = [ '==', @cur_vars ];
            }
            else {
                push @cur_vars, rnd->pick(@not_used);
                my $expr = rnd_pow($vars, 0, $other_counts, $assign);
                $cond = rnd->coin ? [ '<=', @cur_vars, $expr ] : [ '>=', $expr, @cur_vars ];
            }
            @head = ('if', $cond);
            $other_counts->{if}--;
        }
        else {
            $type = $vars->{iterator};
            my $expr = rnd_pow($vars, 1, $other_counts, $assign);
            @cur_vars = new_var($vars->{all});
            @head = ('for', @cur_vars, 0, $expr);
            $other_counts->{counter} and push $children, '=', 'counter', [ '+', 'counter', 1 ];
            $for_count--;
        }

        $type->{$_} = 1 for @cur_vars;
        my $next_for_count;
        do {
            $for_count -= $next_for_count = $for_count ? rnd->in_range(1, $for_count) : 0;
            push $children, make_rnd_block($next_for_count, $other_counts, $vars);
        } while ($for_count);
        delete $type->{$_} for @cur_vars; 
        return @$assign, @head, $children;
    }
    else {
        return final_expr(keys $vars->{iterator});
    }

}

1;
