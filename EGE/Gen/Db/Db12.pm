# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Db::Db12;
use base 'EGE::GenBase::Construct';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog qw(make_expr);
use EGE::Prog::Lang;
use EGE::Html;
use EGE::Russian::City;
use EGE::SQL::Table;
use EGE::SQL::Queries;
use EGE::SQL::Utils;
use EGE::SQL::RandomTable;

sub sql_html { make_expr($_[0])->to_lang_named('SQL', { html => 1 }) }

sub create_nested_query {
    my ($self) = @_;
    my ($gen_db) = EGE::SQL::RandomDatabase::make_database(rnd->in_range(5, 8));
    my @tables = rnd->pick_n(2, @{$gen_db->{relation_table}});
    my (@answer, @wrong_ans, $a, $col, $col_m);
    my $tab = $tables[0];
    my @arrs = grep $tables[0]->find_field($_), @{$tables[1]->{fields}};
    my $field = $arrs[0];
    my @arr_tab = grep $_ ne $field, @{$tab->{fields}};
    my $tab2 = $arr_tab[0]->{ref_field}->{table};
    my $text = $gen_db->make_text($tab, $tab2);
    do {
        $col_m = rnd->in_range(@{$text->{col_range}});
        $col = rnd->pick(1..3);
    } until ($col_m != $col);
    my @variants = (
        EGE::SQL::Select->new($tab2, [])->text_html_tt,
        EGE::SQL::Select->new($tab, [ make_expr([ '()', 'count', $tab->{fields}->[1] ]) ])->text_html_tt);
    $_->assign_field_alias($_->{name}) for ($tab, $tab2);
    push @variants, map html->tag('tt', $_),
        'WHERE', '(',
        sql_html(
            [ '&&', [ '==', $tab2->{fields}->[0], $arr_tab[0] ], [ '>', $tab->{fields}->[-1], $col_m ] ]),
        ')', '&gt;', $col, $col_m, 'GROUP BY', 'HAVING',
        sql_html(
            [ '||', [ '==', $tab2->{fields}->[0], $arr_tab[0] ], [ '>', $tab->{fields}->[-1], $col_m ] ]),
        sql_html(
            [ '&&', [ '==', $tab2->{fields}->[0], $arr_tab[0] ], [ '>', $tab->{fields}->[-1], $col ] ]);
    my @correct = (0, 2, 3, 1, 2, 4, 5, 6, 7);
    my $qtext = sprintf $text->{text}, $col_m, $col;
    $self->{text} = sprintf "Дан фрагмент базы данных:\n%s\n
        Составьте запрос, выполняющий задачу: <br/> $qtext.",
        EGE::SQL::Utils::multi_table_html($tab2, $tab);
    $self->{variants} = [ @variants ];
    $self->{correct} = [ @correct ];
}

1;
