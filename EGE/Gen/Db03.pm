# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db03;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog qw(make_expr make_block);
use EGE::Prog::Lang;
use EGE::Html;
use EGE::SQL::Table;
use EGE::Russian::Product;
use EGE::Russian::Time;
use EGE::SQL::Queries;

sub trivial_update {
    my ($self) = @_;
    my $name_table = "products";
    my @month = rnd->pick_n_sorted(5, @EGE::Russian::Time::month);
    my @electronic = rnd->pick_n(9, @EGE::Russian::Product::electronic);
    my ($products, $values) = EGE::SQL::Utils::create_table( ['Товар', @month], \@electronic);
    my $text_table = $products->table_html();
    my ($cond, $update);
    my ($m1, $m2, $m3, $m4) = rnd->shuffle(@month[0 .. $#month]);
    my ($l, $r) = map $products->random_val($values), 1..2;
    my $e = make_expr([ rnd->pick('>', '<', '<=', '>='), $m1, $m4 ]);
    $update = EGE::SQL::Update->new($products, $name_table,
        make_block ([ '=', $m2, $l, '=', $m3, $r] ), $e);
    $update->run();
    $e = make_expr([ rnd->pick('>', '<', '<=', '>='), $m2,  $m4]);
    my $select = EGE::SQL::Select->new($products, $name_table, [], $e);
    my $ans = $select->run->count();
    $self->{text} =
        "В таблице <tt>products</tt> представлен список товаров: \n$text_table\n" .
        'Сколько товаров в этой таблицы будут удовлетворяют запросу ' . $select->text_html .
        'после выполнения запроса ' . html->row_n('td', $update->text_html),
    $self->variants($ans, rnd->pick_n(3, grep $_ != $ans, 1 .. $products->count));
}

1;
