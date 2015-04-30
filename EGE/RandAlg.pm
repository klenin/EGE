# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::RandAlg;

use strict;
use warnings;

use EGE::Random;
use base 'Exporter';
our @EXPORT_OK = qw(to_logic big_o big_theta make_rnd_block pow make_rnd_if);

sub big_o { "<i>O</i>($_[0])" }
sub big_theta { "<i>&#920;</i>($_[0])" }
sub to_logic { EGE::Prog::make_expr($_[0])->to_lang_named('Logic') }

sub pow { $_[1] == 1 ? $_[0] : [ '**', @_ ] }

sub final_expr {
    ('expr', [ 'print', @_ ]);
}

sub new_var {
    my $var = rnd->index_var;
    $var .= rnd->index_var while $_[0]->{$var};
    $_[0]->{$var} = 1;
    $var;
}

use constant MAX_DEGREE => 3;
use constant P_IF => 0.5;
use constant P_ASSIGN => 0.5;
use constant SUBS_COUNT => 8;

sub rnd_pow {
    my ($vars, $use_iters, $assign, $other_counts) = @_;
    my @all_vars = keys %{$vars->{all}};
    @all_vars = grep !$vars->{iterator}->{$_}, @all_vars unless $use_iters;
    my $var = rnd->pick(@all_vars);
    if ($assign && $other_counts->{assign} && rnd->coin(P_ASSIGN)) {
        $other_counts->{assign}--;
        my $right = rnd_pow($vars, 0);
        $var = new_var($vars->{all});
        push @$assign, '=', $var, $right;
    }
    my $degree = rnd->in_range(1, MAX_DEGREE);
    pow($var, $degree); 
}

sub rnd_poly {
    my $poly = rnd_pow(@_);
    $poly = [ '+', $poly, rnd_pow(@_) ] while rnd->coin;
    $poly = [ '+', $poly, rnd->const_value ] if rnd->coin;
    $poly;
}

sub make_rnd_cond {
    my ($vars, $assign, $other_counts) = @_;
    my @vars = rnd->shuffle(grep !$vars->{if}->{$_}, keys %{$vars->{iterator}});
    my $case = rnd->in_range(0, 3);

    $case == 0 and return [ '==', @vars[0 .. 1] ],                                                      @vars[0 .. 1];
    $case == 1 and return [ '==', [ '%', $vars[0], rnd_pow($vars, 0, $assign, $other_counts) ], 0 ],    $vars[0];
    $case == 2 and return [ '==', $vars[0], 0 ],                                                        $vars[0];
    $case == 3 and return [ '<=', $vars[0], rnd_pow($vars, 0, $assign, $other_counts) ],                $vars[0];
}

# TODO: Добавить генерацию if_mod!
sub make_rnd_block {
    my ($for_count, $other_counts, $vars) = @_;
    if ($for_count) {
        my $assign = [];
        my $children = [];
        my (@head, @used_vars, $type);
        if ($other_counts->{if} && rnd->coin(P_IF) && keys(%{$vars->{iterator}}) - keys(%{$vars->{if}}) >= 2) {
            $type = $vars->{if};
            my @conds;
            my $make_subs = 
                defined $other_counts->{subs}                   # генерировать замены если мы хотели их генерировать
                && ref $other_counts->{subs} ne 'ARRAY'         # и не генерировали до сих пор    
                && rnd->coin(1 / $other_counts->{if}) ? 1 : 0;  # и с вероятностью тем большей, чем меньше 
                                                                # блоков if осталось сгенерировать (вплоть до p=1)
            for (0 .. 1 + $make_subs * SUBS_COUNT) {
                my ($cond, @cur_vars) = make_rnd_cond($vars, $make_subs && $assign, $other_counts);
                push @used_vars, @cur_vars;
                push @conds, $cond;
            }
            @head = ('if', $conds[0]);
            $other_counts->{if}--;
            if ($make_subs) {
                $head[1] = [ '#', "$other_counts->{subs}" ];
                $other_counts->{subs} = [ $head[1], @conds ];
            }
        }
        else {
            $type = $vars->{iterator};
            my $expr = rnd_pow($vars, 1, $assign, $other_counts);
            @used_vars = new_var($vars->{all});
            @head = ('for', @used_vars, 0, $expr);
            $other_counts->{counter} and push @$children, '=', 'counter', [ '+', 'counter', 1 ];
            $for_count--;
        }

        $type->{$_} = 1 for @used_vars;
        my $next_for_count;
        do {
            $for_count -= $next_for_count = $for_count ? rnd->in_range(1, $for_count) : 0;
            push @$children, make_rnd_block($next_for_count, $other_counts, $vars);
        } while ($for_count);
        delete $type->{$_} for @used_vars; 
        return @$assign, @head, $children;
    }
    else {
        return final_expr(keys %{$vars->{iterator}});
    }
}

1;
