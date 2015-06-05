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
    my $ok_table = sub {
        (() = $_[0]->get_columns) >= $p{column} && grep scalar @$_ >= $p{row}, $_[0]->get_rows_array;
    };
    my $class = rnd->pick(grep $ok_table->($_), map "EGE::SQL::$_",
        qw(Products Jobs ProductMonth Cities People Subjects));
    $class->make_table($p{column}, $p{row});
}

package EGE::SQL::BaseTable;
use EGE::Random;

sub make_table {
    my ($self, $column_count, $row_count, $name) = @_;
    my @columns = $self->get_columns;
    my @fields = ($columns[0], rnd->pick_n($column_count - 1, @columns[1 .. $#columns]));
    my @row_sources = grep @$_ >= $row_count, $self->get_rows_array;
    my @rows = rnd->pick_n($row_count, @{rnd->pick(@row_sources)});
    EGE::SQL::Utils::create_table(\@fields, \@rows, $name || $self->get_name);
}

package EGE::SQL::Products;
use base 'EGE::SQL::BaseTable';
sub get_name { 'products' }
sub get_columns { qw(Товар Цена Прибыль Затраты Выручка); }
sub get_rows_array { (
    \@EGE::Russian::Product::candy,
    \@EGE::Russian::Product::electronic,
    \@EGE::Russian::Product::pcs,
    \@EGE::Russian::Product::printers,
    \@EGE::Russian::Product::laptops
) }

package EGE::SQL::Jobs;
use base 'EGE::SQL::BaseTable';
sub get_name { 'jobs' }
sub get_columns { ('Профессия', 'Зарплата'); }
sub get_rows_array { (\@EGE::Russian::Jobs::list) }

package EGE::SQL::ProductMonth;
use base 'EGE::SQL::Products';
sub get_columns { ('Товар', @EGE::Russian::Time::month) }

package EGE::SQL::Cities;
use base 'EGE::SQL::BaseTable';
sub get_name { 'cities' }
sub get_columns { qw(Город Жители Площадь) }
sub get_rows_array { (\@EGE::Russian::City::city) }

package EGE::SQL::People;
use base 'EGE::SQL::BaseTable';
sub get_name { 'people' }
sub get_columns { qw(Фамилия Зарплата) }
sub get_rows_array { (\@EGE::Russian::FamilyNames::list) }

package EGE::SQL::Subjects;
use base 'EGE::SQL::BaseTable';
sub get_name { 'subject' }
sub get_columns { qw(Предмет Часы) }
sub get_rows_array { (\@EGE::Russian::Subjects::list) }

1;
