# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::Gen::Db::Db06;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::SQL::Table;
use EGE::Russian::Product;
use EGE::SQL::Queries;

sub select_between {
    my ($self) = @_;
    my $products = EGE::SQL::RandomTable::create_table(column => 5, row => 9);
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
        "В таблице <tt>%s</tt> представлен список товаров: \n%s\n" .
        "Сколько записей в ней удовлетворяют запросу %s?",
        $products->name, $products->table_html, $select->text_html;
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $products->count()));
}

sub expression {
    my ($self, $ans, $values, @month) = @_;
    my ($cond, $count);
    do {
        my $l = $self->fetch_val($values);
        my ($m1, $m2, $m3) = rnd->shuffle(@month[0 .. $#month]);
        $cond = EGE::Prog::make_expr([
            rnd->pick(ops::add),
            [ rnd->pick(ops::add), $m1, $m2 ],
            $m3,
        ]);
        $count = ${$self->select([$cond])->{data}}[0]->[0];
    } until ($count != $ans);
    $cond;
}

sub select_expression {
    my ($self) = @_;
    my $products = EGE::SQL::RandomTable::create_table(column => 5, row => 3);
    my @month = @{$products->{fields}}[1 .. @{$products->{fields}} - 1];
    my ($count, $ans, $l, @table_false);
    my ($m1, $m2, $m3, $m4) = rnd->shuffle(@month[0 .. $#month]);
    my $values = rnd->pick(@month);
    my $cond = expression($products, 0, $values, @month);
    my $query = EGE::SQL::Select->new($products, [ $m1, $m2, $cond ]);
    my $select = $query->run();
    my $text_ans = $select->table_html;
    $count = ${$query->run()->{data}}[2];
    my $j = 0;
    for (0..2) {
        my $select;
        if ($_ % 2) {
            $select = $products->select([ $m1, $m2, expression($products, $count, $values, @month) ]);
        } else {
            $cond = expression($products, $j, $values, @month);
            $select =  $products->select([ rnd->pick_n(1, $m3, $m4), $m1, $cond ]);
            $j = ${$products->{data}}[2];
        }
        push @table_false, $select->table_html;
    }

    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список товаров: \n%s\n" .
        'Каким будет результат выполнения запроса %s?',
        $products->name, $products->table_html, $query->text_html;
    $self->variants($text_ans, @table_false);
}

1;
