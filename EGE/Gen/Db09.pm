# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db09;
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
    my ($name, $fields, $data_source, $start) = @_;
    my $table = EGE::SQL::Table->new($fields, name => $name);
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
        [ 'pcs', [ qw(id name_pc) ], \@EGE::Russian::Product::pcs ],
        [ 'printers', [ qw(id name_printer) ], \@EGE::Russian::Product::printers ],
        [ 'laptops', [ qw(id name_laptop) ], \@EGE::Russian::Product::laptops ],
    );
    my $buyers = EGE::SQL::Table->new([ qw(id_buyer id_pc id_printer id_laptop) ], name => 'buyers');
    for my $id (rnd->pick_n(8, 1 .. 12)) {
        $buyers->insert_row($id, map $_->random_row->[0], @tables);
    }
    my $make_joins = sub {
        my ($wrong) = @_;
        my $prev = $buyers;
        my @t = rnd->shuffle(@tables);
        $prev = EGE::SQL::Inner_join->new(
            { tab => $prev, field =>
                $buyers->fields->[
                    $wrong == $_ ? rnd->in_range_except(0, scalar @tables, $_) : $_] },
            { tab => $t[$_ - 1], field => 'id' }
        ) for 1 .. @tables;
        $prev;
    };
    my $id = $buyers->random_row->[0];
    my $where = make_expr([ '==', 'id_buyer', $id ]);
    $self->variants(map EGE::SQL::Select->new(
        $make_joins->($_), [ qw(name_pc name_printer name_laptop) ], $where)->text_html, 0..@tables);
    $self->{text} = sprintf
        "В фрагменте базы данных интернет-магазина представлены сведения о покупках:\n%s\n" .
        'Какой из приведенных ниже запросов покажет названия предметов, приобретенных покупателем с id = %s?',
        EGE::SQL::Utils::multi_table_html(@tables, $buyers), $id;
}

1;
