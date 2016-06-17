# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Db::Db06;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Html;
use EGE::Prog;
use EGE::Random;
use EGE::SQL::Queries;
use EGE::SQL::RandomTable;
use EGE::SQL::Table;

sub select_between {
    my ($self) = @_;
    my $rt = EGE::SQL::RandomTable->new(column => 5, row => 9);
    my $rt_class = $rt->pick;
    my $products = $rt->make;
    my @month = @{$products->{fields}}[1 .. @{$products->{fields}} - 1];
    my ($cond, $count,$l, $r, $m1);
    do {
        ($l, $r) = map $products->fetch_val($_), rnd->pick_n(2, @month);
        $m1 = rnd->shuffle(@month[1 .. $#month]);
        $cond = EGE::Prog::make_expr([ 'between', $m1, $l, $r ]);
        $count = $products->select([], $cond)->count();
    } until (1 < $count && $count < $products->count());
    my $select = EGE::SQL::Select->new($products, [], $cond);
    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список %s: \n%s\n" .
        "Сколько записей в ней удовлетворяют запросу %s?",
        $products->name, $rt_class->get_text_name->{genitive},
        $products->table_html, $select->text_html_tt;
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $products->count()));
}

sub random_select_query {
    my ($table, $used) = @_;
    my @fields = @{$table->fields};
    shift @fields;
    my @f = rnd->pick_n(3, @fields);
    my $expr;
    for my $try (1..50) {
        $expr = EGE::Prog::make_expr([
            rnd->pick(ops::add), [ rnd->pick(ops::add), @f[0..1] ], $f[2] ]);
        my $crc = 0;
        $crc ^= $_ for @{$table->select([ $expr ])->column_array(1)};
        $used->{$crc}++ or last;
    }
    EGE::SQL::Select->new($table, [ rnd->shuffle(@fields[0..1], $expr) ]);
}

sub select_expression {
    my ($self) = @_;
    my $rt = EGE::SQL::RandomTable->new(column => 5, row => 3);
    my $rt_class = $rt->pick;
    my $products = $rt->make;
    my $used = {};
    my ($good, @bad) = map random_select_query($products, $used), 1..5;

    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список %s: \n%s\n" .
        'Каким будет результат выполнения запроса %s?',
        $products->name, $rt_class->get_text_name->{genitive},
        $products->table_html, $good->text_html_tt;
    $self->variants(map $_->run->table_html, $good, @bad);
}

1;
