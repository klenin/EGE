# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::SQL::RandomTable;
use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::SQL::Utils;

sub create_table {
    my %p = @_;
    my @arr = ('EGE::SQL::Products', 'EGE::SQL::Jobs', 'EGE::SQL::ProductMonth',
            'EGE::SQL::Cities');
    my $class = rnd->pick(grep ($_->get_column() >= $p{column} && grep (@$_ >= $p{row}, $_->get_rows_array()), @arr));
    $class->make_table($p{column}, $p{row});
}

package EGE::SQL::BaseTable;
use EGE::Random;
sub make_table {
    my ($self, $column_count, $row_count) = @_;
    my @columns = $self->get_column();
    my @fields =($columns[0], rnd->pick_n($column_count - 1, @columns[1 .. $#columns]));
    my @rows = rnd->pick_n($row_count, @{rnd->pick(grep @$_ >= $row_count, $self->get_rows_array())});
    EGE::SQL::Utils::create_table(\@fields, \@rows,  $self->get_name());
}

package EGE::SQL::Products;
use base 'EGE::SQL::BaseTable';
sub get_name { 'product' }
sub get_column { my @product = ('Товар', 'Прибыль', 'Цена', 'Затраты', 'Выручка'); }
sub get_rows_array { (\@EGE::Russian::Product::candy, \@EGE::Russian::Product::electronic, \@EGE::Russian::Product::pcs,
    \@EGE::Russian::Product::printers, \@EGE::Russian::Product::laptops) }

package EGE::SQL::Jobs;
use base 'EGE::SQL::BaseTable';
sub get_name { 'jobs' }
sub get_column { my @jobs = ('Профессия', 'Зарплата'); }
sub get_rows_array { (\@EGE::Russian::Jobs::list)}

package EGE::SQL::ProductMonth;
use base 'EGE::SQL::Products';
sub get_column { my @product = ('Товар', @EGE::Russian::Time::month); }

package EGE::SQL::Cities;
use base 'EGE::SQL::BaseTable';
sub get_name { 'city' }
sub get_column { my @city = ('Город', 'Жители', 'Площадь'); }
sub get_rows_array { (\@EGE::Russian::City::city) }

1;
