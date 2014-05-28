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
    my ($products, $values) = EGE::SQL::Utils::create_table(\@fields, \@candy, 'products');
    my $cond = EGE::SQL::Utils::check_cond($products, $values, \&EGE::SQL::Utils::expr_2, @fields);
    my $query = EGE::SQL::Select->new($products, [ 'Товар' ], $cond);
    my $selected = $query->run();
    my %ans;
    $ans{$_->[0]} = 1 for @{$selected->{data}};
    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список товаров:\n%s\n" .
        'Какие товары в этой таблицы удовлетворяют запросу %s?',
        $products->name, $products->table_html, $query->text_html;
    $self->variants(@candy);
    $self->{correct} = [ map $ans{$_} ? 1 : 0, @candy ];
}

1;
