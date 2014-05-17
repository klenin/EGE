# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db05;
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
    my $name_table = 'Products';
    my ($products, $values) = EGE::SQL::Utils::create_table( \@fields,
            [ map $candy[$_] , 0..$#candy-5 ]);
    my $text_table = $products->select([@fields])->table_html();
    my (%ans, @query);
    my $ind = rnd->in_range(10, 13);
    my @val = map rnd->in_range(0, 50) * 100 , 1..@fields-1;
    $products->insert_row ($candy[$ind], @val); 
    push @query, " <tt>INSERT INTO $name_table (Товар, Количество, Цена, Затраты) 
        VALUES ( '$candy[$ind]', '$val[0]', '$val[1]', '$val[2]') </tt> \n";
    while (1) {
        my ($f1, $f2, $f3) = rnd->shuffle(@fields[1 .. $#fields]);
        my ($l, $r) = map $products->random_val($values), 1..2;
        my $cond = EGE::Prog::make_expr([
            rnd->pick('&&', '||'),
            [ rnd->pick(ops::comp), $f1, $l ], 
            [ '>', $f2, $f1 ],
        ]);
        my $ans_pr = $products->select([], $cond)->count();
        if (0 < $ans_pr && $ans_pr < $products->count()) { 
            my $delete = EGE::SQL::Delete->new($products, $name_table, $cond);
            $delete->run();
            push @query, $delete->text_html(); 
            last;
        }
    } 
    my $selected = $products->select([ 'Товар' ]);
    $ans{$_->[0]} = 1 for @{$selected->{data}};
    $self->{text} =
        "В таблице <tt>products</tt> представлен список товаров: \n".$text_table."\n".
        "Какие товары в ней будут после выполнения приведенных ниже запросов? \n" ;
    $self->{text} .= html->row_n('td', $_) for @query;     
    $self->variants(@candy);
    $self->{correct} = [ map $ans{$_} ? 1 : 0, @candy ];
}

1;
