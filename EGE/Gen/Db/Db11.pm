# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Db::Db11;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::Russian::City;
use EGE::SQL::Table;
use EGE::SQL::Queries;
use EGE::SQL::Utils;
use EGE::SQL::RandomTable;
use EGE::Prog;
use EGE::Prog::Lang;

sub _create_inner_join {
    my ($tab1, $tab2, $field1, $field2) = @_;
    EGE::SQL::InnerJoin->new(
        { tab => $tab1, field => $tab1->{name} . ".$field1" },
        { tab => $tab2, field => $field2 });
}

sub trivial_aggregate_func {
    my ($self) = @_;
    my ($gen_db) = EGE::SQL::RandomDatabase::make_database(rnd->in_range(5,8));
    my @tables = @{$gen_db->{relation_table}};
    my (@wrong_ans, $a);
    my @arrs = grep $tables[0]->find_field($_), @{$tables[1]->{fields}};
    my $field = $arrs[0];
    my @arr_tab = grep $_ ne $field, @{$tables[1]->{fields}};
    my $table = $arr_tab[0]->{ref_field}->{table};
    my $text = $gen_db->make_text($tables[0], $tables[1]);
    my $name_field = $text->{name_field};
    my $inner = _create_inner_join($tables[0], $tables[1], $field, $field);
    my $func = rnd->pick('sum', 'avg', 'min', 'max');
    my $name = rnd->pick(@{$tables[1]->{data}});
    my $where = EGE::Prog::make_expr([ '==', $arr_tab[0], @$name[1]]);
    my $select = EGE::SQL::Select->new($inner, [ EGE::Prog::make_expr(['()', $func, $name_field]) ], $where);
    $_->assign_field_alias($_->{name}) for @tables;
    push @wrong_ans, EGE::SQL::Select->new(_create_inner_join($_, $a = rnd->pick(@tables),  @{$_->{fields}}[0], $field), 
        [ EGE::Prog::make_expr(['()', $func, $name_field])], 
        EGE::Prog::make_expr([ rnd->pick('<', '>', '!='), @{$a->{fields}}[1], @$name[1]]))
            for $tables[1], rnd->pick_n(2, @{$gen_db->{database}->{tables}});
    my $ans = $table->select($table->{fields}, EGE::Prog::make_expr(['==', @{$table->{fields}}[0], @$name[1]]));
    my $data = @{$ans->{data}}[0];
    my $family_name = @{$ans->{fields}}[1] eq 'Фамилия' ?  @$data[1] . ' ' . @$data[2] : @$data[1];
    my $aggr_func = { 'sum' => 'суммарная' , 'avg'=> 'средняя', 
        'min'=> 'минимальная', 'max'=> 'максимальная'};
    $self->{text} = sprintf
        "Дан фрагмент базы данных:\n%s\n".
        'Выберите запрос отвечающий на вопрос:<br/>' . $text->{text} . ' %s?',
        EGE::SQL::Utils::multi_table_html(@{$gen_db->{database}->{tables}}, @tables),
        $aggr_func->{$func},
        $family_name;
    $self->variants($select->text_html, map $_->text_html, @wrong_ans);
}

sub inner_join_count {
    my ($self) = @_;
    my $table_person = EGE::SQL::RandomTable::create_table(column => 1, row => 0);
    my $table_city;
    do {
        $table_city = EGE::SQL::RandomTable::create_table(column => 1, row => 0);
    } until ($table_city->name ne $table_person->name);
    my $n = rnd->in_range(10, 50) * 100;
    my $m = rnd->in_range(60, 90) * 100;
    $_->insert_column(name => 'id', array => [ 1..$_->count ]) for $table_person, $table_city;
    $_->insert_column(name => 'marks', array => [ 1..$_->count ], index => 2) for $table_person, $table_city;
    my $op = rnd->pick('>=', '<=', '>', '<');
    my $expr = EGE::Prog::make_expr([$op, @{$table_city->{fields}}[2], @{$table_person->{fields}}[2]]);
    my $r = rnd->pick(1..100);
    my $if1 = EGE::Prog::make_expr([$op, @{$table_city->{fields}}[2], $r]);
    my $if2 = EGE::Prog::make_expr([$op, $r, @{$table_person->{fields}}[2]]);
    $_->assign_field_alias($_->{name}) for ($table_person, $table_city);
    my @variants = map abs(EGE::Prog::make_expr([$_, $m, $n])->run()), ('*', '//', '+', '%');
    push @variants, map abs(EGE::Prog::make_expr(['**', $_, 2])->run()), ($n, $m);
    my $inner = EGE::SQL::InnerJoinExpr->new($expr,
        { tab => $table_person, field => 'marks' },
        { tab => $table_city, field => 'marks' });
    my $select =  EGE::SQL::Select->new($inner, []);
    $self->{text} = sprintf
        "В таблице %s %s записей, структура таблицы следующая %s где " . html->tag('tt', html->cdata('%s')) . "<br/>".
        "Так в таблице %s %s записей, структура таблицы следующая %s где " . html->tag('tt', html->cdata('%s')) . "<br/>".
        'Сколько записей будет в таблице в результате выполнения запроса: %s',
        $table_person->name, $n, $table_person->table_html, $if2->to_lang_named('SQL'),
        $table_city->name, $m, $table_city->table_html, $if1->to_lang_named('SQL'),
        $select->text_html;
    $self->variants(@variants, $n, $m);
}

1;
