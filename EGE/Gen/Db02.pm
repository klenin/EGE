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
    my ($products, $values) = EGE::SQL::Utils::create_table( \@fields, \@candy);
    my (%ans, $query);
    while (1) {
        my ($f1, $f2, $f3) = rnd->shuffle(@fields[1 .. $#fields]);
        my ($l, $r) = map $products->random_val($values), 1..2;
        my $e = EGE::Prog::make_expr([
            rnd->pick('&&', '||'),
            [
                rnd->pick('&&', '||'),
                [ rnd->pick(ops::comp), $f1, $l ],
                [ '>', $f2, $f1 ],
            ], 
            [ rnd->pick(ops::comp), $f3, $r ],
        ]);
        $query = EGE::SQL::Select->new($products, 'products', [ 'Товар' ], $e);
        my ($selected) = $query->run();
        if (1 < $selected->count() && $selected->count() < $products->count() - 2) {
            $ans{$_->[0]} = 1 for @{$selected->{data}};
            last;
        }
    }
    $self->{text} =
        "В таблице <tt>products</tt> представлен список товаров: \n" .
        $products->select([@fields])->table_html() . "\n" .
        "Какие товары в этой таблицы удовлетворяют запросу " . $query->text_html() . "?\n",
    $self->variants(@candy);
    $self->{correct} = [ map $ans{$_} ? 1 : 0, @candy ];
}

1;
