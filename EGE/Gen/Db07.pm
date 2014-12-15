# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db07;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::Russian::City;
use EGE::SQL::Table;
use EGE::SQL::Queries;
use EGE::SQL::Utils;

sub create_table {
    my ($n, $m, $k) = @_;
    my @city = rnd->pick_n($n, @EGE::Russian::City::city);
    my @families = rnd->pick_n_sorted($m, @EGE::Russian::FamilyNames::list);
    my $table_city = EGE::SQL::Table->new([ qw(id Город) ], name => 'cities');
    my $table_person = EGE::SQL::Table->new([ qw(Фамилия cid) ], name => 'persons');
    $table_city->insert_rows(@{EGE::Utils::transpose([ 1..@city ], \@city)});
    my @id_city = rnd->pick_n($m, 1 .. @city + $k);
    $table_person->insert_rows(@{EGE::Utils::transpose(\@families, \@id_city)});
    $table_city, $table_person;
}

sub trivial_inner_join{
    my ($self) = @_;
    my ($table_city, $table_person) = create_table(12, 7, 10);
    my $count = $table_person->inner_join($table_city, 'cid', 'id')->count();
    my $inner = EGE::SQL::Inner_join->new(
        { tab => $table_person, field => 'cid' },
        { tab => $table_city, field => 'id' });
    my $query = EGE::SQL::Select->new($inner, []);
    $self->{text} = sprintf
        "Даны две таблицы:\n%s\n" .
        'Сколько записей будет содержать результат запроса %s?',
        EGE::SQL::Utils::multi_table_html($table_city, $table_person),
        $query->text_html;
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $table_person->count()));
}

1;
