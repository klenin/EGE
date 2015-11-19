# Copyright © 2010 Alexander S. Klenin
# Copyright © 2015 R. Kravchuk
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::EGE::B09;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
sub join_comma { join(', ', @_[0 .. $#_ - 1]) . ', ' . $_[-1] }

my @roads = map [], 1..11;
my @city_path_count = map 0, 1..11;
my @city_id_to_char = ('А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И', 'К');

sub dfs {
	my $city = shift;
	return 1 if $city == 10;
	return $_ if ($_ = $city_path_count[$city]);
	for (@{$roads[$city]}) {
		$city_path_count[$city] += dfs($_);
	}
	return $city_path_count[$city];
}

sub city_roads {
	@roads[0] = [1..3];
	for (7..9) {@roads[$_] = [10]};

	for my $i(1, 4) {
		my @next_cities = $i+3..$i+5;
		my @required_cities = rnd->shuffle(@next_cities);
		for my $j(0..2) {
			my $curr_city = $i+$j;
			my $next_city =  pop @required_cities;  
			push @{$roads[$curr_city]}, $next_city;
			for (@next_cities) {
				push @{$roads[$curr_city]}, $_ if rnd->coin() && $_ != $next_city;
			}
		}
	}

	my ($self) = @_;
	$self->{text} = "<p>В таблице представлена схема дорог соединяющих города ".
					join_comma(@city_id_to_char).". Двигаться по дорогам можно только ".
					"из города указанном в верхней строке, в город указанный в нижней строке. ".
					"Сколько существует различных дорог из города А в город К?</p><table>";
	my $top_row = my $middle_row = my $bottom_row = "<tr>";
	for (my $curr_city_id = 0; $curr_city_id < scalar @roads; $curr_city_id++) {
		for my $next_city_id(@{$roads[$curr_city_id]}) {
			$top_row.="<td>".$city_id_to_char[$curr_city_id]."</td>";
			$middle_row.="<td>↓</td>";
			$bottom_row.="<td>".$city_id_to_char[$next_city_id]."</td>";
		}
	}
	
	map $_.="</tr>", ($top_row, $middle_row, $bottom_row);
	$self->{text}.=$top_row.$middle_row.$bottom_row."</table>";
	
	$self->{correct} = dfs(0);
	
	$self->accept_number;	
}

1;