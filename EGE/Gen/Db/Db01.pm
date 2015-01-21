# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

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

sub trivial_select {
    my ($self) = @_;
    my @fields = qw(Профессия Зарплата);
    my @jobs = rnd->pick_n(9, @EGE::Russian::Jobs::list);
    my ($products, $values) = EGE::SQL::Utils::create_table(\@fields, \@jobs, 'jobs');
    my $gen_expr = sub {
        EGE::Prog::make_expr([ rnd->pick(ops::comp), 'Зарплата', $products->random_val($values) ])
    };
    my $selected = EGE::SQL::Select->new($products, [],
        EGE::SQL::Utils::check_cond($products, $values, $gen_expr, @fields));
    my $count = $selected->run->count;
    $self->{text} = sprintf
        "Заработная плата по профессиям представлена в таблице <tt>%s</tt>:\n%s\n" .
        'Сколько записей в ней удовлетворяют запросу %s?',
        $products->name, $products->table_html, $selected->text_html;
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $products->count()));
}

sub trivial_delete {
    my ($self) = @_;
    my @fields = qw(Товар Количество Цена Затраты);
    my @candy = rnd->pick_n(9, @EGE::Russian::Product::candy);
    my ($products, $values) = EGE::SQL::Utils::create_table(\@fields, \@candy, 'products');
    my $text =  $products->table_html;
    my $count = $products->count();
    my $delete = EGE::SQL::Delete->new($products,
        EGE::SQL::Utils::check_cond($products, $values, \&EGE::SQL::Utils::expr_1, @fields));
    my $ans = $count - $delete->run()->count();
    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список товаров:\n%s\n" .
        'Сколько записей удалит из нее запрос %s?',
        $products->name, $text, $delete->text_html;
    $self->variants($ans, rnd->pick_n(3, grep $_ != $ans, 1 .. $count));
}

1;
