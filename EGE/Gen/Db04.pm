# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE


package EGE::Gen::Db04;
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
use EGE::SQL::Queries;


sub expression {
    my ($f1, $f2, $f3, $f4, @field) = @_;
    my $cond = make_expr([
            rnd->pick('&&', '||'),
            [rnd->pick('>','<','<=','>='), $f1, $f2],
            [rnd->pick('>','<','<=','>='), $f3, $f2],
    ]);
}

my $name_table = 'Products';

sub func {
    my ($count, $self, @fields) = @_;
    my @ans;
    for (0..2) {
        my ($cond, $tab);
        my ($f1, $f2, $f3, $f4);
        while(1) {
            $tab = $self->select([@fields]);
            ($f1, $f2, $f3, $f4) =  rnd->shuffle(@fields[1 .. $#fields]); ;
            $cond = expression($f1, $f2, $f3, $f4, @fields);
            if ($tab->select([], $cond)->count() > 1 && $tab->select([], $cond)->count() != $count) {
                last;
            }
        } 
        my $update = EGE::SQL::Update->new($self, $name_table, make_block(['=', $f4, $f2]), $cond);
        push @ans, $update->text_html;
    }
    @ans;
}

sub choose_update {
    my ($self) = @_;
    my @fields = qw(Товар Прибыль Цена Затраты Выручка);
    my @electronic = rnd->pick_n(6, @EGE::Russian::Product::electronic);
    my ($products, $values) = EGE::SQL::Utils::create_table( \@fields, \@electronic);
    my $table_text = $products->table_html();
    my (@requests, $update);
    while(1) {
        my ($f1,$f2, $f3, $f4) = rnd->shuffle(@fields[1 .. $#fields]); 
        my $cond = expression($f1,$f2, $f3,$f4, @fields);
        my $count = $products->select([], $cond)->count();
        if ($count){
            @requests = func($count, $products, @fields);
            $update = EGE::SQL::Update->new($products, $name_table, make_block([ '=', $f1, $f4 ]), $cond);
            $update->run();
            last;
        } 
    }
    my $text =  $update->text_html();
    my $table_text_ans = $products->table_html();
    $self->{text} = 
        "В таблице <tt>Products</tt> представлен список товаров: \n$table_text\n" .
        "В таблице <tt>Products</tt> представлен список товаров после выполнения запросов: \n$table_text_ans\n ".
        "Какой запрос надо выполнить чтобы из первой таблицы получить вторую?",
    $self->variants($text, @requests);
}

1;