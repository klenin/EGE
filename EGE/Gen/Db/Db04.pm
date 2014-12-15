# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE


package EGE::Gen::Db::Db04;
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

sub func {
    my ($count, $table, @fields) = @_;
    my @ans;
    for (0..2) {
        my ($cond, $tab);
        my ($f1, $f2, $f3, $f4);
        while(1) {
            $tab = $table->select([@fields]);
            ($f1, $f2, $f3, $f4) = rnd->shuffle(@fields[1 .. $#fields]); ;
            $cond = expression($f1, $f2, $f3, $f4, @fields);
            if ($tab->select([], $cond)->count() > 1 && $tab->select([], $cond)->count() != $count) {
                last;
            }
        }
        my $update = EGE::SQL::Update->new($table, make_block([ '=', $f4, $f2 ]), $cond);
        push @ans, $update->text_html;
    }
    @ans;
}

sub choose_update {
    my ($self) = @_;
    my @fields = qw(Товар Прибыль Цена Затраты Выручка);
    my @electronic = rnd->pick_n(6, @EGE::Russian::Product::electronic);
    my ($products, $values) = EGE::SQL::Utils::create_table(\@fields, \@electronic, 'products');
    my $old_table_text = $products->table_html;
    my (@requests, $update);
    while(1) {
        my ($f1, $f2, $f3, $f4) = rnd->shuffle(@fields[1 .. $#fields]);
        my $cond = expression($f1, $f2, $f3, $f4, @fields);
        my $count = $products->select([], $cond)->count();
        if ($count) {
            @requests = func($count, $products, @fields);
            $update = EGE::SQL::Update->new($products, make_block([ '=', $f1, $f4 ]), $cond);
            $update->run();
            last;
        }
    }
    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список товаров<br/>до выполнения запроса: \n%s\n" .
        "после выполнения запроса: \n%s\n" .
        'Какой запрос надо выполнить, чтобы из первой таблицы получить вторую?',
        $products->name, $old_table_text, $products->table_html;
    $self->variants($update->text_html, @requests);
}

1;
