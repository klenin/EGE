# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::Db::Db02;
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
    my $products = EGE::SQL::RandomTable::create_table(column => 4, row => 8);
    my $name_fld = $products->{fields}[0];
    my ($selected, $query);
    do {
        my $cond = EGE::SQL::Utils::check_cond($products, \&EGE::SQL::Utils::expr_2);
        $query = EGE::SQL::Select->new($products, [ $name_fld ], $cond);
        $selected = $query->run;
    } until $selected->count > 1;
    my %ans;
    $ans{$_->[0]} = 1 for @{$selected->{data}};
    $self->{text} = sprintf
        "Имеется таблица <tt>%s</tt>:\n%s\n" .
        'Какие товары в этой таблице удовлетворяют запросу %s?',
        $products->name, $products->table_html, $query->text_html;
    $self->variants(my @v = @{$products->column_array($name_fld)});
    $self->{correct} = [ map $ans{$_} ? 1 : 0, @v ];
}

1;
