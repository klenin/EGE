# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::Db::Db05;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Html;
use EGE::SQL::Table;
use EGE::SQL::Queries;
use EGE::SQL::RandomTable;
use EGE::SQL::Utils;

sub insert_delete {
    my ($self) = @_;
    my $products = EGE::SQL::RandomTable::create_table(column => 5, row => 13);
    my $delete_cond = EGE::SQL::Utils::check_cond($products, \&EGE::SQL::Utils::expr_3);

    my $f = $products->{fields}->[0];
    my $all_names = $products->column_array($f);
    my @insert_rows = splice @{$products->{data}}, 0, 2;
    my $text_table = $products->table_html;

    my @sqls = (
        map(EGE::SQL::Insert->new($products, $_), @insert_rows),
        EGE::SQL::Delete->new($products, $delete_cond));
    $_->run for @sqls;

    my %ans;
    @ans{@{$products->column_array($f)}} = undef;

    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список товаров: \n%s\n" .
        "Какие товары в ней будут после выполнения приведенных ниже запросов?\n%s",
        $products->name, $text_table,
        html->table([ map html->row_n('td', $_->text_html_tt), @sqls ]);
    $self->variants(@$all_names);
    $self->{correct} = [ map exists $ans{$_} ? 1 : 0, @$all_names ];
}

1;
