# Copyright © 2010 Alexander S. Klenin
# Copyright © 2015 R. Kravchuk
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::EGE::Z15;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Russian;
use EGE::Html;
use EGE::Graph;
use Clone qw(clone);
use List::Util qw(min max);

my @grids = (
    {
        vertices => {
            'А' => {at => [ 0  , 50  ], in => [                         ], min_inners => 0},
            'Б' => {at => [ 50 , 0   ], in => [ 'А', 'В', 'Д'           ], min_inners => 2},
            'В' => {at => [ 100, 50  ], in => [ 'А', 'Б', 'Г', 'Д', 'Е' ], min_inners => 3},
            'Г' => {at => [ 50 , 100 ], in => [ 'А', 'В', 'Е'           ], min_inners => 1},
            'Д' => {at => [ 150, 0   ], in => [ 'Б', 'В', 'Ж'           ], min_inners => 2},
            'Ж' => {at => [ 200, 50  ], in => [ 'В', 'Д', 'Е'           ], min_inners => 1},
            'Е' => {at => [ 150, 100 ], in => [ 'Г', 'В', 'Ж'           ], min_inners => 1},
            'И' => {at => [ 250, 0   ], in => [ 'Д', 'Ж'                ], min_inners => 1},
            'К' => {at => [ 300, 50  ], in => [ 'И', 'Ж', 'Е', 'Д'      ], min_inners => 2},
        },
        first_city => 'А',
        last_city  => 'К',
    },
    {
        vertices => {
            'А' => {at => [ 0  , 100 ], in => [                         ], min_inners => 0},
            'Б' => {at => [ 45 , 35  ], in => [ 'А', 'В', 'Ж'           ], min_inners => 2},
            'В' => {at => [ 50 , 100 ], in => [ 'А', 'Б', 'Г', 'Е'      ], min_inners => 3},
            'Г' => {at => [ 45 , 150 ], in => [ 'А', 'В', 'Д'           ], min_inners => 1},
            'Д' => {at => [ 40 , 200 ], in => [ 'А', 'Г',               ], min_inners => 2},
            'Е' => {at => [ 110, 20  ], in => [ 'Б', 'В', 'Ж'           ], min_inners => 1},
            'Ж' => {at => [ 100, 84  ], in => [ 'Е', 'Б', 'В', 'Г',     ], min_inners => 2},
            'З' => {at => [ 107, 140 ], in => [ 'Ж', 'Г', 'Д', 'И'      ], min_inners => 1},
            'И' => {at => [ 150, 193 ], in => [ 'Д', 'З'                ], min_inners => 1},
            'К' => {at => [ 200, 120 ], in => [ 'Е', 'Ж', 'З', 'И'      ], min_inners => 3},
        },
        first_city => 'А',
        last_city  => 'К',
    }
);

sub dfs {
    my ($city, $l_city, $g) = @_;
    return 1 if $city eq $l_city;
    return $g->{vertices}->{$city}->{count} if exists $g->{vertices}->{$city}->{count};
    $g->{vertices}->{$city}->{count} = 0;
    $g->{vertices}->{$city}->{count} += dfs($_, $l_city, $g) for (keys %{$g->{edges}->{$city}});
    $g->{vertices}->{$city}->{count};
}

sub update_inners {
    my ($city, $inner, $g) = @_;
    $g->{vertices}->{$city}->{inners}->{$inner} = 0;
    $g->{vertices}->{$city}->{inners}->{$_} = 0 for (keys %{$g->{vertices}->{$inner}->{inners}});
}

sub forward_dfs {
    my ($city, $inner, $g) = @_;
    update_inners($city, $inner, $g);
    forward_dfs($_, $city, $g) for (keys %{$g->{edges}->{$city}});
}

sub generate_graph {
    my $grid = clone(shift);
    my $vertices = $grid->{vertices};
    my $g = EGE::Graph->new(vertices => $vertices);
    my $fc = $grid->{first_city};
    my $lc = $grid->{last_city};
    for my $v(rnd->shuffle(keys %$vertices)) {
        my @inners = @{$vertices->{$v}->{in}} or next;
        @inners = rnd->pick_n(rnd->in_range($vertices->{$v}->{min_inners}, scalar @inners), @inners);
        while (@inners) {
            my $ci = pop @inners;
            next if exists $g->{vertices}->{$ci}->{inners}->{$v};
            forward_dfs($v, $ci, $g);
            $g->edge1($ci, $v);
        }
    }
    $g;
}

sub city_roads {
    my ($self) = @_;

    my $g;
    my $iter = 0;
    my $answer;
    my $grid;

    do {
        $grid = rnd->pick(@grids);
        $g = generate_graph($grid);
        $answer = dfs($grid->{first_city}, $grid->{last_city}, $g);
    } until (($answer >= 7 && $answer <= 20) || $iter++ > 20);
    
    $self->{text} = sprintf
        '<p>В таблице представлена схема дорог, соединяющих города %s. ' .
        'Двигаться по дорогам можно только из города, указанного в верхней строке, ' .
        'в город, указанный в нижней строке. ' .
        'Сколько существует различных дорог из города %s в город %s?</p> %s',
        EGE::Russian::join_comma_and(sort keys %{$g->{vertices}}),
        $grid->{first_city}, $grid->{last_city},
        html->div($g->as_svg, {html->style(width => '500px', height => '500px', margin => '0 auto')});
    $self->{correct} = $answer;
    $self->accept_number;
}

1;
