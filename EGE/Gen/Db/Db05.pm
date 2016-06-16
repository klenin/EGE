# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

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
use EGE::SQL::RandomTable qw(create_table);

sub insert_delete {
    my ($self) = @_;
    my $products = EGE::SQL::RandomTable::create_table(column => 5, row => 13);
    my (%ans, @query);
    my $candy = $products->column_array($products->{fields}[0]);
    my $ind = rnd->in_range(7, 10);
    my @val = map rnd->in_range(10, 80) * 100 , 1..@{$products->{fields}} - 1;
    $products->{data} = [ grep $_->[0] ne @$candy[$ind], @{$products->{data}} ];
    my $text_table = $products->table_html;
    $products->insert_row(@$candy[$ind], @val);
    my $insert = EGE::SQL::Insert->new($products, [ @$candy[$ind] , @val ]);
    my $new_candy = $products->column_array($products->{fields}[0]);
    push @query, $insert->text_html_tt();
    my $cond = EGE::SQL::Utils::check_cond($products, \&EGE::SQL::Utils::expr_3);
    my $delete = EGE::SQL::Delete->new($products, $cond);
    $delete->run();
    push @query, $delete->text_html_tt();
    my $selected = $products->select([ $products->{fields}[0] ]);
    $ans{$_->[0]} = 1 for @{$selected->{data}};
    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список товаров: \n%s\n" .
        "Какие товары в ней будут после выполнения приведенных ниже запросов?\n",
        $products->name, $text_table;
    $self->{text} .= html->row_n('td', $_) for @query;
    $self->variants(@$new_candy);
    $self->{correct} = [ map $ans{$_} ? 1 : 0, @$new_candy ];
}

1;
