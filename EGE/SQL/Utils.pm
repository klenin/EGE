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
    $products, @values;
}

sub check_cond {
    my ($products, $values, $expr, @fields) = @_;
    my ($ans, $cond);
    my $count = $products->count();
    do {
        $cond = $expr->($products, $values, @fields);
        $ans = $products->select([], $cond)->count();
    } until (0 < $ans && $ans < $count);
    $cond;
}

sub expr_1 {
    my ($tab, $values, @fields) = @_;
    my ($f1,$f2) = rnd->shuffle(@fields[1 .. $#fields]);
    EGE::Prog::make_expr([ rnd->pick(ops::comp), $f1, $f2 ]);
}

sub expr_2 {
    my ($tab, $values, @fields) = @_;
    my ($f1, $f2, $f3) = rnd->shuffle(@fields[1 .. $#fields]);
    my ($l, $r) = map $tab->random_val($values), 1..2;
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
    my ($tab, $values, @fields) = @_;
    my ($f1, $f2, $f3) = rnd->shuffle(@fields[1 .. $#fields]);
    my ($l, $r) = map $tab->random_val($values), 1..2;
    EGE::Prog::make_expr([
        rnd->pick('&&', '||'),
        [ rnd->pick(ops::comp), $f1, $l ], 
        [ '>', $f2, $f1 ],
    ]);
}

1;
