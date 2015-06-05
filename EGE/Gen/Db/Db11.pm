# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
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
        $table_person->name, $n, $table_person->table_html, $if1->to_lang_named('SQL'),
        $table_city->name, $m, $table_city->table_html, $if2->to_lang_named('SQL'),
        $select->text_html;
    $self->variants(@variants, $n, $m);
}

1;
