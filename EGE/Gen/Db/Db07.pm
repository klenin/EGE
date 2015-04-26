# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::Gen::Db::Db07;
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

sub trivial_inner_join{
    my ($self) = @_;
    my $table_person = EGE::SQL::People->make_table(1, 7);
    my $table_city  = EGE::SQL::Cities->make_table(1, 7);
    $table_person->insert_column(name => 'id', array=>[1..$table_person->count()]);
    my @arr = rnd->pick_n(scalar $table_city->count(), 1 .. $table_city->count() + 10);
    $table_city->insert_column(name => 'cid', array => \@arr, index => 1);
    my $count = $table_person->inner_join($table_city, 'id', 'cid')->count();
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
