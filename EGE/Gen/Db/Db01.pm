# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::Db::Db01;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::Russian::Jobs;
use EGE::SQL::Table;
use EGE::SQL::Utils qw(create_table check_cond expr_1);
use EGE::SQL::RandomTable qw(create_table);

sub trivial_select {
    my ($self) = @_;
    my $products = EGE::SQL::RandomTable::create_table(column => 2, row => 8);
    my $gen_expr = sub {
         EGE::Prog::make_expr([ rnd->pick(ops::comp), $products->{fields}[1], $products->fetch_val($products->{fields}[1]) ])
    };
    my $selected = EGE::SQL::Select->new($products, [],
       EGE::SQL::Utils::check_cond($products, $gen_expr));
    my $count = $selected->run->count;
    $self->{text} = sprintf
    "Дана таблица <tt>%s</tt>:\n%s\n" .
    'Сколько записей в ней удовлетворяют запросу %s?',
    $products->name, $products->table_html, $selected->text_html_tt;

    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $products->count()));
}

sub trivial_delete {
    my ($self) = @_;
    my $products = EGE::SQL::RandomTable::create_table(column => 4, row => 6);
    my $text =  $products->table_html;
    my $count = $products->count();
    my $delete = EGE::SQL::Delete->new($products,
        EGE::SQL::Utils::check_cond($products, \&EGE::SQL::Utils::expr_1));
    my $ans = $count - $delete->run()->count();
    $self->{text} = sprintf
        "Дана таблица <tt>%s</tt> :\n%s\n" .
        'Сколько записей удалит из нее запрос %s?',
        $products->name, $text, $delete->text_html_tt;
    $self->variants($ans, rnd->pick_n(3, grep $_ != $ans, 1 .. $count));
}

1;
