# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db06;
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

my(@month);

sub create_table {
    my ($n, $m) = @_;
    @month = rnd->pick_n_sorted($n, @EGE::Russian::Time::month);
    my @electronic = rnd->pick_n($m, @EGE::Russian::Product::electronic);
    my ($products, $values) = EGE::SQL::Utils::create_table( ['Товар', @month], \@electronic);
    ($products, $values);
}

sub select_between {
    my ($self) = @_;
    my ($products, $values) = create_table(5, 9);
    my $name_table = 'products';
    my ($cond, $count,$l, $r, $m1);
    do {
        ($l, $r) = map $products->random_val($values), 1..2;
        $m1 = rnd->shuffle(@month[1 .. $#month]);
        $cond = EGE::Prog::make_expr([ 'between', $m1, $l, $r ]);
        $count = $products->select([], $cond)->count();
    } until (1 < $count && $count < $products->count());
    my $select = EGE::SQL::Select->new($products, $name_table, [], $cond);
    $self->{text} =
        "В таблице <tt>$name_table</tt> представлен список товаров: \n" . $products->table_html() . "\n" .
        "Сколько записей в ней удовлетворяют запросу " .$select->text_html() . " ?",
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $products->count()));
}

sub expression {
    my ($self, $ans, $values) = @_;
    my ($cond, $count); 
    do {
        my $l = $self->random_val($values);
        my ($m1, $m2, $m3) = rnd->shuffle(@month[0 .. $#month]); 
        $cond = EGE::Prog::make_expr([
                    rnd->pick(ops::add),
                    [ rnd->pick(ops::add), $m1, $m2 ], 
                    $m3,
                ]);
        $count = ${$self->select([$cond])->{data}}[0];        
    } until ($count != $ans);
    $cond;
}

sub select_expression {
    my ($self) = @_;
    my ($products, $values) = create_table(5, 3);
    my $table_name = 'Products';
    my ($cond, $count, $ans, $l, @table_false);
    my ($m1, $m2, $m3, $m4) = rnd->shuffle(@month[0 .. $#month]);
    $cond = expression($products, 0, $values);
    my $query = EGE::SQL::Select->new($products, $table_name, [ $m1, $m2, $cond ]);
    my $text_query = $query->text_html();  
    my $select = $query->run();
    my $text_ans = $select->table_html();
    $count = ${$query->run()->{data}}[2];
    my $j = 0;
    for (0..2) {
        my $select;
        if ($_ % 2) { 
            $select =  $products->select([ $m1, $m2, expression($products, $count, $values)]);
        } else {
            $cond = expression($products, $j, $values);
            $select =  $products->select([ rnd->pick_n(1, $m3, $m4), $m1, $cond]);
            $j = ${$products->{data}}[2];
        } 
        push @table_false, $select->table_html();    
    }
    
    $self->{text} =
        "В таблице <tt>$table_name</tt> представлен список товаров: \n" . $products->table_html() . "\n" .
        "Какой будет результат выполнения данного запроса $text_query?",
    $self->variants($text_ans, @table_false);
}

1;