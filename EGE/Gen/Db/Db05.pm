# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::Gen::Db::Db05;
use base 'EGE::GenBase::MultipleChoice';

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

sub insert_delete {
    my ($self) = @_;
    my @fields = qw(Товар Количество Цена Затраты);
    my @candy = rnd->pick_n(14, @EGE::Russian::Product::candy);
    my ($products, $values) = EGE::SQL::Utils::create_table(
        \@fields, [ map $candy[$_] , 0..$#candy - 5 ], 'products');
    my $text_table = $products->table_html;
    my (%ans, @query);
    my $ind = rnd->in_range(10, 13);
    my @val = map rnd->in_range(0, 50) * 100 , 1..@fields - 1;
    $products->insert_row($candy[$ind], @val);
    my $insert = EGE::SQL::Insert->new($products, [ $candy[$ind], @val ]);
    push @query, $insert->text_html();
    my $cond = EGE::SQL::Utils::check_cond($products, $values, \&EGE::SQL::Utils::expr_3, @fields);
    my $delete = EGE::SQL::Delete->new($products, $cond);
    $delete->run();
    push @query, $delete->text_html();
    my $selected = $products->select([ 'Товар' ]);
    $ans{$_->[0]} = 1 for @{$selected->{data}};
    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список товаров: \n%s\n" .
        "Какие товары в ней будут после выполнения приведенных ниже запросов?\n",
        $products->name, $text_table;
    $self->{text} .= html->row_n('td', $_) for @query;
    $self->variants(@candy);
    $self->{correct} = [ map $ans{$_} ? 1 : 0, @candy ];
}

1;
