# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::SQL::RandomTable;
use strict;
use warnings;
use utf8;

use EGE::Random;

sub new {
    my ($class, %p) = @_;
    bless { %p }, $class;
}

sub ok_table {
    my ($self, $table) = @_;
    (() = $table->get_columns) >= $self->{column} &&
    grep scalar @$_ >= $self->{row}, $table->get_rows_array;
}

sub pick {
    my ($self) = @_;
    $self->{class} = rnd->pick(grep $self->ok_table($_), map "EGE::SQL::$_",
        qw(Products Jobs ProductMonth Cities People Subjects));
}

sub make {
    my ($self) = @_;
    $self->{class}->make_table($self->{column}, $self->{row});
}

sub create_table {
    my %p = @_;
    my $self = __PACKAGE__->new(%p);
    $self->pick;
    $self->make;
}

package EGE::SQL::BaseTable;

use EGE::Random;
use EGE::SQL::Utils;

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
sub get_text_name { { nominative => 'товары', genitive => 'товаров' } }

package EGE::SQL::Jobs;
use base 'EGE::SQL::BaseTable';
sub get_name { 'jobs' }
sub get_columns { ('Профессия', 'Зарплата'); }
sub get_rows_array { (\@EGE::Russian::Jobs::list) }
sub get_text_name { { nominative => 'профессии', genitive => 'профессий' } }

package EGE::SQL::ProductMonth;
use base 'EGE::SQL::Products';
sub get_columns { ('Товар', @EGE::Russian::Time::month) }

package EGE::SQL::Cities;
use base 'EGE::SQL::BaseTable';
sub get_name { 'cities' }
sub get_columns { qw(Город Население Население2010 Население2020 Площадь Продажи) }
sub get_rows_array { (\@EGE::Russian::City::city) }
sub get_text_name { { nominative => 'города', genitive => 'городов' } }

package EGE::SQL::People;
use base 'EGE::SQL::BaseTable';
sub get_name { 'persons' }
sub get_columns { qw(Фамилия Зарплата Продажи) }
sub get_rows_array { (\@EGE::Russian::FamilyNames::list) }
sub get_text_name { { nominative => 'сотрудники', genitive => 'сотрудников' } }

package EGE::SQL::Subjects;
use base 'EGE::SQL::BaseTable';
sub get_name { 'subject' }
sub get_columns { qw(Предмет ЧасыЛекций ЧасыПрактики ЧасыЛаб) }
sub get_rows_array { (\@EGE::Russian::Subjects::list) }
sub get_text_name { { nominative => 'предметы', genitive => 'предметов' } }

1;
