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
    my $insert =  EGE::SQL::Insert->new ($products, $name_table, [ $candy[$ind], @val ]); 
    push @query, $insert->text_html(); 
    my $cond = EGE::SQL::Utils::check_cond ($products, $values, \&EGE::SQL::Utils::expr_3 ,@fields);
    my $delete = EGE::SQL::Delete->new($products, $name_table, $cond);
    $delete->run();
    push @query, $delete->text_html();     
    my $selected = $products->select([ 'Товар' ]);
    $ans{$_->[0]} = 1 for @{$selected->{data}};
    $self->{text} =
        "В таблице <tt>$name_table</tt> представлен список товаров: \n".$text_table."\n".
        "Какие товары в ней будут после выполнения приведенных ниже запросов? \n" ;
    $self->{text} .= html->row_n('td', $_) for @query;     
    $self->variants(@candy);
    $self->{correct} = [ map $ans{$_} ? 1 : 0, @candy ];
}

1;
