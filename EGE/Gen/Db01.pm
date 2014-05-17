# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db01;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::Russian::Jobs;
use EGE::SQL::Table;
use EGE::SQL::Utils;

sub check_cond {
    my ($products, $values, @fields) = @_;
    my ($ans, $cond);
    my $count = $products->count();
    do {
        my $d =  $products->random_val($values);
        my ($f1,$f2) = rnd->shuffle(@fields[1 .. $#fields]);
        $cond = EGE::Prog::make_expr([ rnd->pick(ops::comp), $f1, $f2]);
        $ans = $products->select([], $cond)->count();
    } until (0 < $ans && $ans < $count);
    $cond;
}

sub trivial_select {
    my ($self) = @_;
    my @fields = qw(Товар Количество Цена Затраты);
    my @candy = rnd->pick_n(9, @EGE::Russian::Product::candy);
    my ($products, $values) = EGE::SQL::Utils::create_table( \@fields, \@candy);
    my $selected = EGE::SQL::Select->new($products, 'products', [], check_cond ($products, $values, @fields));
    my $count = $selected->run()->count;
    $self->{text} =
        "Заработная плата по профессиям представлена в таблице <tt>products</tt>: \n" .
        $products->table_html() . "\n" .
        "Сколько записей в ней удовлетворяют запросу " . $selected->text_html() . " ?",
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $products->count()));
}

sub trivial_delete {
    my ($self) = @_;
    my @fields = qw(Товар Количество Цена Затраты);
    my @candy = rnd->pick_n(9, @EGE::Russian::Product::candy);
    my ($products, $values) = EGE::SQL::Utils::create_table( \@fields, \@candy);
    my $text_table = $products->table_html();
    my $count = $products->count();
    my $delete = EGE::SQL::Delete->new($products, "products", check_cond ($products, $values, @fields));
    my $ans = $count - $delete->run()->count();
    $self->{text} =
        "В таблице <tt>products</tt> представлен список товаров:\n$text_table\n" .
        "Сколько записей из нее удалит запрос " . $delete->text_html()."?",
    $self->variants($ans, rnd->pick_n(3, grep $_ != $ans, 1 .. $count));
}

1;
