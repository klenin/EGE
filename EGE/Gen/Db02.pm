# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db02;
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

sub select_where {
    my ($self) = @_;
    my @field = qw(Товар Количество Цена Затраты);
    my $table_products = EGE::SQL::Table->new(['id', @field]); 
    my @candy = rnd->pick_n(9, @EGE::Russian::Product::candy);
    my (@values); 
    @values = map [ map rnd->in_range(10, 80) * 100, @candy ], 0..@field-2;
    $table_products->insert_rows(@{EGE::Utils::transpose([ 0..$#candy ], \@candy, $values[0], $values[1], $values[2])});
    my $cond = '';
    my (@ans, $query, $select);
    push @ans, 0 for @candy;
    while (1) {
        my ($s1, $s2, $s3) = rnd->pick_n(3, 1 .. @field-1);
        my $l = $table_products->random_val(@values);
        my $r = $table_products->random_val(@values);
        my $e = EGE::Prog::make_expr([
            rnd->pick('&&', '||'),
            [
                rnd->pick('&&', '||'),
                [ rnd->pick(ops::comp), $field[$s1], $l ], 
                [ '>', $field[$s2], $field[$s1] ],
            ], 
            [ rnd->pick(ops::comp), $field[$s3], $r ],
        ]);
        $query = EGE::SQL::Select->new($table_products, 'products', [ 'id' ], $e);
        $select = $query->run();
        if ($select->count() -1 > 0&& $select->count() < $table_products->count()- 2) { 
            $cond = html->cdata($e->to_lang_named('SQL'));
            $ans[$$_[0]] = 1 for @{$select->{data}};
            last;
        }
    }
    $self->{text} =
        "В таблице <tt>products</tt> представлен список товаров: \n".$table_products->select([@field])->table_html()."\n" .
        "Какие товары в этой таблицы удовлетворяют запросу <tt>".$query->text()."</tt>?\n",
    $self->variants(@candy);
    $self->{correct} = \@ans;
}

1;