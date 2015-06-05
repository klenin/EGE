# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::SQL::RandomDatabase;
use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::SQL::Utils;


sub make_database {
    my ($m) = @_;
    rnd->coin ? EGE::SQL::EducationDb->new($m) : EGE::SQL::ProductDb->new($m);
}

sub make_text {
    my ($self, $tab1, $tab2) = @_;
    my $relation = $self->relation;
    my $rel_hash = $relation->{potential_relation}->{$tab1->name}->{$tab2->name};
    if (defined $rel_hash->{name_field}) {
        my $range = $relation->{potential_field}->{$rel_hash->{name_field}};
        my $tab = defined $rel_hash->{inversion} ? $tab2 : $tab1;
        $tab->insert_column(name => $rel_hash->{name_field},
            array => [ map rnd->in_range(@$range), 1 .. $tab->count ],
            index => scalar @{$tab->fields});
    }
    $rel_hash;
}

package EGE::SQL::Database;
use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::SQL::Utils;

sub new {
    my ($class, $tables) = @_;
    my $self->{tables} = $tables;
    bless $self, $class;
}

sub add_table {
    my ($self, $table) = @_;
    push @{$self->{tables}}, $table;
    $self;
}

sub find_table_ {
    my ($self, $name) = @_;
    for my $n (@$name) {
        for (@{$self->{tables}}) {
            return $_ if $_->{name} eq $n;
        }
    }
}

package EGE::SQL::EducationDb;
use base 'EGE::SQL::RandomDatabase';
use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::SQL::Utils;

sub relation {
    my $rel = {
        potential_relation => {
            students => {
                lecturers => { text => 'Какие преподаватели преподают у студента' },
                students_subject => {
                    name_field => 'marks',
                    col_range => [ 2, 5],
                    text => 'Выбрать студентов у которых есть больше %s оценок равных %s',
                    inversion => 1 },
                students => { name_field => 'курс', text => 'Посчитать количество студентов на каждом курсе' },
            },
            lecturers => {
                students => { text => 'У каких студентов преподаёт' },
            },
            subject => {
                students => { text =>'Кто изучает предмет' },
                lecturers => { text => 'Кто преподаёт предмет' }
            },
            students_subject => {
                lecturers_subject => { name_field => 'marks', text => 'Какая %s оценка была поставлена преподавателем' },
                students_subject => { name_field => 'marks', text => 'Посчитать количество студентов по оценкам' },
                students => {
                    name_field => 'marks',
                    col_range => [ 2, 4 ],
                    text => 'Выбрать студентов сдавших предмет на оценку больше %s и таких предметов у студента больше %s' }
            },
            lecturers_subject => {
                lecturers => {
                    name_field => 'часы',
                    col_range => [ 100, 200 ],
                    text => 'Выбрать преподавателей у которых часов по предмету больше %s и таких предметов больше %s' }
            },
        },
        potential_field => {
            marks => [ 2, 5 ],
            часы => [ 100, 200 ],
            курс => [ 1, 5 ],
        }
    };
}

sub new {
    my ($class, $m) = @_;
    my $self = {
        database => EGE::SQL::Database->new (
            [
                EGE::SQL::People->make_table(1, $m, 'lecturers'),
                EGE::SQL::People->make_table(1, $m, 'students'),
                EGE::SQL::Subjects->make_table(1, int($m / 2))
            ]),
    };
    my @males = EGE::Russian::Names::different_males(2 * $m);
    my $i = 0;
    $_->insert_column(name => 'Имя', array => [ @males[$m * $i .. $m * ++$i] ], index => 1)
        for @{$self->{database}->{tables}}[0], @{$self->{database}->{tables}}[1];
    $_->insert_column(name => 'id', array => [ 1 .. $_->count ]) for @{$self->{database}->{tables}};
    $self->{relation_table} = [
        EGE::SQL::Utils::related(@{$self->{database}->{tables}}[1]->fields->[0], @{$self->{database}->{tables}}[2]->fields->[0],
            map rnd->pick(@{@{$self->{database}->{tables}}[2]->column_array('id')}), 1 .. $m),
        EGE::SQL::Utils::related(@{$self->{database}->{tables}}[0]->fields->[0], @{$self->{database}->{tables}}[2]->fields->[0],
            @{@{$self->{database}->{tables}}[2]->column_array('id')})
    ];
    bless $self, $class;
}

package EGE::SQL::ProductDb;
use base 'EGE::SQL::RandomDatabase';
use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::SQL::Utils;

sub relation {
    {
        potential_relation => {
            cities => {
                products => { text => 'Какие товары покупают в городе' },
            },
            products => {
                cities => { text => 'Где покупали' },
                people_products => {
                    name_field => 'склад',
                    col_range => [1, 5],
                    text => 'Выбрать продукты которые купили больше %s человек, со склада № %s',
                    inversion => 1 },
                products => { name_field => 'склад', text => 'Посчитать количество товаров на каждом складе' }
            },
            people => {
                cities => { text => 'Где живет' },
                products => { text => 'Что купил' }
            },
            people_cities => {
                cities => {
                    name_field => 'количество',
                    col_range => [ 1, 4 ],
                    text => 'Выбрать города в которых количество купленых товаров больше %s и таких товаров больше %s' }
            },
            people_products => {
                people_cities => { name_field => 'rating', text => 'Какая %s оценка была поставлена товарам в городе' },
                people_products => { name_field => 'rating', text => 'Посчитать количество товаров по оценкам' },
                products => {
                    name_field => 'rating',
                    col_range => [ 2, 4 ],
                    text => 'Выбрать товары у которых rating больше %s, у больше чем %s покупателей' }
            },
        },
        potential_field => {
            количество => [ 1, 5 ],
            склад => [ 1, 5 ],
            price => [ 1000, 5000 ],
            rating => [ 2, 5 ],
        }
    }
}

sub new {
    my ($class, $m) = @_;
    my $self = {
        database => EGE::SQL::Database->new (
            [
                EGE::SQL::People->make_table(1, $m),
                EGE::SQL::Products->make_table(1, int($m / 2)),
                EGE::SQL::Cities->make_table(1, int($m / 2))
            ]),

    };
    my @males = EGE::Russian::Names::different_males(2 * $m);
    my $i = 0;
    @{$self->{database}->{tables}}[0]->insert_column(name => 'Имя', array => [ @males[$m * $i .. $m * ++$i] ], index => 1);
    $_->insert_column(name => 'id', array => [ 1 .. $_->count ]) for @{$self->{database}->{tables}};
    $self->{relation_table} = [
        EGE::SQL::Utils::related(@{$self->{database}->{tables}}[0]->{fields}->[0], @{$self->{database}->{tables}}[1]->fields->[0],
            map rnd->pick(@{@{$self->{database}->{tables}}[1]->column_array('id')}), 1 .. $m),
        EGE::SQL::Utils::related(@{$self->{database}->{tables}}[0]->{fields}->[0], @{$self->{database}->{tables}}[2]->fields->[0],
            map rnd->pick(@{@{$self->{database}->{tables}}[2]->column_array('id')}), 1 .. $m),
    ];
    bless $self, $class;
}

1;

