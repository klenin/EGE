# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::Gen::Db::Db09;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Prog qw(make_expr);
use EGE::Random;
use EGE::Russian::Product;
use EGE::SQL::Table;
use EGE::SQL::Queries;
use EGE::SQL::Utils;

sub _make_table {
    my ($name, $data_source, $start) = @_;
    my $table = EGE::SQL::Table->new([ 'id', "name_$name" ], name => $name . 's');
    $table->{ref_field} = "id_$name";
    my @data = rnd->pick_n(6, @$data_source);
    $table->insert_rows(@{EGE::Utils::transpose(
        [ rnd->shuffle($$start .. $$start + $#data) ], \@data)});
    $$start += @data;
    $table;
}

sub inner_join {
    my ($self) = @_;
    my $start = 1;
    my @tables = map _make_table(@$_, \$start), (
        [ 'pc', \@EGE::Russian::Product::pcs ],
        [ 'printer', \@EGE::Russian::Product::printers ],
        [ 'laptop', \@EGE::Russian::Product::laptops ],
    );
    my $buyers = EGE::SQL::Table->new([ 'id_buyer', map $_->{ref_field}, @tables ], name => 'buyers');
    for my $id (rnd->pick_n(8, 1 .. 12)) {
        $buyers->insert_row($id, map $_->random_row->[0], @tables);
    }
    my $make_joins = sub {
        my ($wrong) = @_;
        my $prev = $buyers;
        my @t = rnd->shuffle(@tables);
        $prev = EGE::SQL::InnerJoin->new(
            { tab => $prev, field => $t[$wrong == $_ ? rnd->in_range_except(0, $#t, $_) : $_]->{ref_field} },
            { tab => $t[$_], field => 'id' }
        ) for 0 .. $#t;
        $prev;
    };
    my $id = $buyers->random_row->[0];
    my $where = make_expr([ '==', 'id_buyer', $id ]);
    ${$_->{fields}}[1]->{name_alias} = $_->{name}, for @tables;
    $self->variants(map EGE::SQL::Select->new(
        $make_joins->($_), [ map (${$_->{fields}}[1], @tables ) ], $where)->text_html, -1..$#tables);
    $self->{text} = sprintf
        "В фрагменте базы данных интернет-магазина представлены сведения о покупках:\n%s\n" .
        'Какой из приведенных ниже запросов покажет названия предметов, приобретенных покупателем с id = %s?',
        EGE::SQL::Utils::multi_table_html(@tables, $buyers), $id;
}

1;
