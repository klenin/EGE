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
use EGE::Html;
use List::Util qw(min max);

my @roads;
my @city_path_count;
my @city_id_to_char = ('А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ж', 'З', 'И', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т');

my $last_city_id;
my $look_back_size = 6;
my $max_inner_road_count = 4;
my $min_last_city_id = 8;
my $max_last_city_id = 15;

sub dfs {
    my $city_id = shift;
    return 1 if $city_id == $last_city_id;
    return $city_path_count[$city_id] if ($city_path_count[$city_id]);
    for (@{$roads[$city_id]}) {
        $_ > $city_id or die "LOOP";
        $city_path_count[$city_id] += dfs($_);
    }
    return $city_path_count[$city_id];
}

sub city_roads {
    my ($self) = @_;
    $last_city_id = rnd->in_range($min_last_city_id, $max_last_city_id);
    @roads = map [], 0..$last_city_id;
    @city_path_count = map 0, 0..$last_city_id;

    for my $i(1..$last_city_id) {
        for (rnd->pick_n(min(rnd->in_range(1, $max_inner_road_count), $i), max (0, $i-$look_back_size)..$i-1)) {
            push @{$roads[$_]}, $i;
        }
    }

    my @top_row;
    my @middle_row;
    my @bottom_row;
    for my $curr_city_id(0..$last_city_id) {
        for my $next_city_id(@{$roads[$curr_city_id]}) {
            push @top_row, $city_id_to_char[$curr_city_id];
            push @middle_row, "↓";
            push @bottom_row, $city_id_to_char[$next_city_id];
        }
    }

    my $table = join '', map html->row("td", @{$_}), (\@top_row, \@middle_row, \@bottom_row); 

    $self->{text} = 
    html->p("В таблице представлена схема дорог соединяющих города ".
    (join ', ', @city_id_to_char[0..$last_city_id]).". Двигаться по дорогам можно только 
    из города указанном в верхней строке, в город указанный в нижней строке. 
    Сколько существует различных дорог из города А в город $city_id_to_char[$last_city_id]?").
    html->table($table, {html->style("margin-left" => "30px", "border-collapse" => "collapse"), border => "1px"});

    $self->{correct} = dfs(0);

    $self->accept_number;
}

1;
