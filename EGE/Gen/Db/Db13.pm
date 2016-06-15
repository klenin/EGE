# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::Gen::Db::Db13;
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

sub trivial_group_by {
    my ($self) = @_;
    my ($gen_db) = EGE::SQL::RandomDatabase::make_database(rnd->in_range(5,8));
    my @tables = @{$gen_db->{relation_table}};
    my $tab = $tables[0];
    my @arrs = grep $tables[0]->find_field($_), @{$tables[1]->{fields}};
    my $field_ne = $arrs[0];
    my @arr_tab = grep $_ ne $field_ne, @{$tab->{fields}};
    my $tab2 = $arr_tab[0]->{ref_field}->{table};
    my @ans_tab = ($tab2, $tab);
    $tab = rnd->coin ? $tab : $tab2;
    my $text = $gen_db->make_text($tab, $tab); 
    my $name_field = $text->{name_field};
    my $field = $tab->name ne $tab2->name ? $arr_tab[0] : $tab->fields->[0];
    my @variants;
    push @variants, sprintf html->tag('tt', html->cdata('%s')), $_ for ( 'SELECT', 'FROM', $name_field, $tab->{name},
        $name_field . ', ' . EGE::Prog::make_expr(['()', 'count', $field])->to_lang_named('SQL'),
        'GROUP BY', 'HAVING',
        EGE::Prog::make_expr(['()', 'count', $field_ne])->to_lang_named('SQL') , $tab2->fields->[1]);
    my @correct = (0, 4, 1, 3, 5, 2);
    $self->{text} = sprintf "Дан фрагмент базы данных:\n%s\n
        Составьте запрос отвечающий на вопрос <br/>
        $text->{text}?",
        EGE::SQL::Utils::multi_table_html(@ans_tab);
    $self->{variants} = [ @variants ];
    $self->{correct} = [ @correct ];
}

sub prepare_variant {
    my ($v) = @_;
    html->tag('tt', join(', ',
        map $_->to_lang_named('SQL', { html => 1 }), ref $v eq 'ARRAY' ? @$v : $v));
}

sub group_by_having {
    my ($self) = @_;
    my ($gen_db) = EGE::SQL::RandomDatabase::make_database(rnd->in_range(5,8));
    my @tables = @{$gen_db->{relation_table}};
    my $tab = $tables[0];
    my @arrs = grep $tables[1]->find_field($_), @{$tables[0]->{fields}};
    my $field_ne = $arrs[0];
    my @arr_tab = grep $_ ne $field_ne, @{$tab->{fields}};
    my $tab2 = $arr_tab[0]->{ref_field}->{table};
    my @ans_tab = ($tab2, $tab);
    my $text = $gen_db->make_text($tab2, $tab);
    $_->assign_field_alias($_->{name}) for ($tab2, $tab);
    my $name_field = $tab->find_field($text->{name_field});
    my $col = rnd->pick(2..5);
    my $col_f = rnd->in_range_except(@{$text->{col_range}}, $col);

    my @variants = (
        map(html->tag('tt', $_), 'SELECT', 'FROM', 'WHERE', 'GROUP BY', 'HAVING', $tab->name, $tab2->name), # 0..6
        EGE::SQL::InnerJoin->new(
            { tab => '', field => $tab2->{name} . ".$arr_tab[0]->{ref_field}" },
            { tab => $tab, field => $arr_tab[0] })->text_html,
        map prepare_variant($_),
            $name_field, # 8
            [ $tab2->fields->[0], $tab2->fields->[1] ],
            [ $tab2->fields->[0], $tab2->fields->[1], make_expr([ '()', 'count', $field_ne ]) ],
            make_expr([ '==', $name_field, $col_f ]),
            make_expr([ '>', [ '()', 'count', $field_ne ], $col ]), # 12
            make_expr([ '==', $name_field, $col ]),
            make_expr([ rnd->pick('>', '<', '=>', '<='), $name_field, $col_f ])
    );
    my @correct = (0, 9, 1, 6, 7, 2, 11, 3, 9, 4, 12);
    $self->{text} = sprintf 'Дан фрагмент базы данных:%s' .
        "Составьте запрос:<br/> $text->{text}.",
        EGE::SQL::Utils::multi_table_html(@ans_tab), $col_f, $col;
    $self->{variants} = [ @variants ];
    $self->{correct} = [ @correct ];
}

1;
