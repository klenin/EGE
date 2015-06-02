# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::SQL::Utils;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;
use EGE::Utils;
use EGE::SQL::Table;
use EGE::SQL::Queries;

sub create_table {
    my ($row, $col, $name) = @_;
    my $products = EGE::SQL::Table->new($row, name => $name);
    my @values = map [ map rnd->in_range(10, 80) * 100, @$col ], 0 .. @$row - 2;
    $products->insert_rows(@{EGE::Utils::transpose($col, @values)});
    $products;
}

sub check_cond {
    my ($products, $expr) = @_;
    my ($ans, $cond);
    my $count = $products->count();
    do {
        $cond = $expr->($products, @{$products->{fields}});
        $ans = $products->select([], $cond)->count();
    } until (0 < $ans && $ans < $count);
    $cond;
}

sub expr_1 {
    my ($tab, @fields) = @_;
    my ($f1, $f2) = rnd->shuffle(@fields[1 .. $#fields]);
    EGE::Prog::make_expr([ rnd->pick(ops::comp), $f1, $f2 ]);
}

sub expr_2 {
    my ($tab, @fields) = @_;
    my ($f1, $f2, $f3) = rnd->shuffle(@fields[1 .. $#fields]);
    my ($l, $r) = map $tab->fetch_val($_), ($f1,$f3);
    EGE::Prog::make_expr([
        rnd->pick('&&', '||'),
        [
            rnd->pick('&&', '||'),
            [ rnd->pick(ops::comp), $f1, $l ],
            [ '>', $f2, $f1 ],
        ],
        [ rnd->pick(ops::comp), $f3, $r ],
    ]);
}

sub expr_3 {
    my ($tab, @fields) = @_;
    my ($f1, $f2, $f3) = rnd->shuffle(@fields[1 .. $#fields]);
    my $l = $tab->fetch_val($f1);
    EGE::Prog::make_expr([
        rnd->pick('&&', '||'),
        [ rnd->pick(ops::comp), $f1, $l ], 
        [ '>', $f2, $f1 ],
    ]);
}

sub multi_table_html {
    html->table(
        html->row_n('td', map html->tag('tt', $_->name), @_) .
        html->tag('tr',
            join ('', map(html->td($_->table_html), @_)),
            { html->style('vertical-align' => 'top') })
    )
}

sub related {
    my ($field1, $field2, @array) = @_;
    my $table = EGE::SQL::Table->new([ map $_.'_'.$_->{table}->{name} , ($field1, $field2) ],
        name => $field1->{table}->{name}.'_'.$field2->{table}->{name});
    my $start = 1;
    $table->insert_rows(@{EGE::Utils::transpose(
        [ rnd->pick_n(scalar @array, @{$field1->{table}->column_array($field1)}) ], [ rnd->shuffle(@array) ])});
    ${$table->{fields}}[0]->{ref_field} = $field1;
    ${$table->{fields}}[1]->{ref_field} = $field2;
    $table;
}

sub table_related{
    my ($self, $field, @array) = @_;
    my $table = $field->{table};
    my @ans;
    foreach my $tab (@array) {
        foreach  (@{$tab->{fields}}) {
            push @ans, $tab if $_->{ref_field}->{table} == $table && $_->{ref_field}->{name} eq $field->{name};
        }
    }
    @ans;
}

1;
