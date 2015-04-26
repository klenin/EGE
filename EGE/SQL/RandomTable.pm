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
            'EGE::SQL::Cities', 'EGE::SQL::People', 'EGE::SQL::Subjects');
    my $class = rnd->pick(grep ($_->get_column() >= $p{column} && grep (@$_ >= $p{row}, $_->get_rows_array()), @arr));
    $class->make_table($p{column}, $p{row});
}

sub education_db {
    my ($self) = @_;
    my $m = rnd->in_range(5,8);  my $i = 0;
    my $lecturer = EGE::SQL::People->make_table(1, $m, 'lecturer');
    my $student = EGE::SQL::People->make_table(1, $m, 'students');
    my $subject = EGE::SQL::Subjects->make_table(2, int($m / 2));
    my @males = EGE::Russian::Names::different_males(2*$m);
    $_->insert_column(name => 'Имя', array => [ @males[$m*$i..$m*++$i] ], index => 1) for ($student, $lecturer);
    $_->insert_column(name => 'id', array => [1..$_->count()]) for ($subject, $student, $lecturer);
    $lecturer->{text} = {$student->{name} => "У каких студентов преподает "};
    $student->{text} = {$lecturer->{name} => "Какие преподаватели преподают у студента"};
    $subject->{text} = {$student->{name} => "Кто изучает предмет" , $lecturer->{name} => "Кто ведет предмет"};
    my @tables;
    push @tables, EGE::SQL::Utils::related(${$lecturer->{fields}}[0], ${$subject->{fields}}[0] , @{$subject->column_array('id')});
    push @tables, EGE::SQL::Utils::related(${$student->{fields}}[0], ${$subject->{fields}}[0], map rnd->pick(@{$subject->column_array('id')}), 1.. $m );
    [ $lecturer, $student, $subject ], @tables;
}

sub product_db {
    my ($self) = @_;
    my $m = rnd->in_range(5,8);
    my $buyers = EGE::SQL::People->make_table(1, $m);
    my $product = EGE::SQL::Products->make_table(2, $m);
    my $cities = EGE::SQL::Cities->make_table(1, $m);
    my @males = EGE::Russian::Names::different_males($m);
    $buyers->insert_column(name => 'Имя', array => \@males , index => 1);
    $_->insert_column(name => 'id', array => [1..$_->count()]) for ($cities, $product, $buyers);
    $cities->{text} = {$product->{name} => "Какие товары покупают в городе "};
    $product->{text} = {$cities->{name} => "В каком городе купили "};
    $buyers->{text} = {$cities->{name} => "Где живет", $product->{name} => "Что купил"};
    my @tables;
    push @tables, EGE::SQL::Utils::related(${$cities->{fields}}[0], ${$buyers->{fields}}[0], @{$buyers->column_array('id')});
    push @tables, EGE::SQL::Utils::related(${$product->{fields}}[0], ${$buyers->{fields}}[0], @{$buyers->column_array('id')});
    [ $cities, $product, $buyers ] , @tables;
}

package EGE::SQL::BaseTable;
use EGE::Random;
sub make_table {
    my ($self, $column_count, $row_count, $name) = @_;
    my @columns = $self->get_column();
    my @fields = ($columns[0], rnd->pick_n($column_count - 1, @columns[1 .. $#columns]));
    my @rows = rnd->pick_n($row_count, @{rnd->pick(grep @$_ >= $row_count, $self->get_rows_array())});
    EGE::SQL::Utils::create_table(\@fields, \@rows, $name ? $name : $self->get_name());
}

package EGE::SQL::Products;
use base 'EGE::SQL::BaseTable';
sub get_name { 'products' }
sub get_column { my @product = ('Товар', 'Цена', 'Прибыль', 'Затраты', 'Выручка'); }
sub get_rows_array { (\@EGE::Russian::Product::candy, \@EGE::Russian::Product::electronic, \@EGE::Russian::Product::pcs,
    \@EGE::Russian::Product::printers, \@EGE::Russian::Product::laptops) }

package EGE::SQL::Jobs;
use base 'EGE::SQL::BaseTable';
sub get_name { 'jobs' }
sub get_column { my @jobs = ('Профессия', 'Зарплата'); }
sub get_rows_array { (\@EGE::Russian::Jobs::list)}

package EGE::SQL::ProductMonth;
use base 'EGE::SQL::Products';
sub get_column { my @products = ('Товар', @EGE::Russian::Time::month); }

package EGE::SQL::Cities;
use base 'EGE::SQL::BaseTable';
sub get_name { 'cities' }
sub get_column { my @cities = ('Город', 'Жители', 'Площадь'); }
sub get_rows_array { (\@EGE::Russian::City::city) }

package EGE::SQL::People;
use base 'EGE::SQL::BaseTable';
sub get_name { 'people' }
sub get_column { my @people = ('Фамилия', 'Зарплата'); }
sub get_rows_array { (\@EGE::Russian::FamilyNames::list) }

package EGE::SQL::Subjects;
use base 'EGE::SQL::BaseTable';
sub get_name { 'subject' }
sub get_column { my @people = ('Предмет', 'Часы'); }
sub get_rows_array { (\@EGE::Russian::Subjects::list) }


1;
