# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db02;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Html;
use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Russian::Product;
use EGE::SQL::Table;
use EGE::SQL::Queries;

sub select_where {
    my ($self) = @_;
    my @fields = qw(Товар Количество Цена Затраты);
    my @candy = rnd->pick_n(9, @EGE::Russian::Product::candy);
    my ($products, $values) = EGE::SQL::Utils::create_table(\@fields, \@candy);
    my (%ans, $query);
    my $cond = EGE::SQL::Utils::check_cond($products, $values, \&EGE::SQL::Utils::expr_2, @fields);
    $query = EGE::SQL::Select->new($products, 'products', [ 'Товар' ], $cond);
    my ($selected) = $query->run();
    $ans{$_->[0]} = 1 for @{$selected->{data}};
    $self->{text} =
        "В таблице <tt>products</tt> представлен список товаров: \n" .
        $products->select([@fields])->table_html() . "\n" .
        'Какие товары в этой таблицы удовлетворяют запросу ' . $query->text_html() . "?\n",
    $self->variants(@candy);
    $self->{correct} = [ map $ans{$_} ? 1 : 0, @candy ];
}

1;
