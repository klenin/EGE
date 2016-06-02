# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Db::Db10;
use base 'EGE::GenBase::MultipleChoice';

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
use EGE::SQL::RandomDatabase qw(make_database);

sub _create_inner_join {
    my ($tab1, $tab2, $field1, $field2) = @_;
    EGE::SQL::InnerJoin->new(
        { tab => '', field => $tab1->{name} . ".$field1" },
        { tab => $tab2, field => $field2 });
}

sub many_inner_join {
    my ($self) = @_;
    my ($gen_db) = EGE::SQL::RandomDatabase::make_database(rnd->in_range(5,8));
    my $tabs = $gen_db->{database}->{tables};
    my @tab = rnd->pick_n(2, @{$gen_db->{relation_table}});
    my (@answer, @wrong_ans);
    my @arrs = grep $tab[0]->find_field($_), @{$tab[1]->{fields}};
    my $field = $arrs[0];
    my @arr_tab = grep $_ ne $field, @{$tab[1]->{fields}};
    my ($question, $name_table, $select);
    my @f = grep $_ ne $field, @{$tab[0]->{fields}};
    push @answer, _create_inner_join($f[0]->{ref_field}->{table}, $tab[0], $f[0]->{ref_field}, $f[0]);
    if (rnd->coin) {
        push @answer, _create_inner_join($tab[0], $tab[1], $field, $field);
        my $f2 = $arr_tab[0];
        push @answer, _create_inner_join($tab[1], $f2->{ref_field}->{table}, $f2, $f2->{ref_field});
        $name_table = $f[0]->{ref_field}->{table};
        $question = $f2->{ref_field}->{table};
        $select = EGE::SQL::Select->new($f[0]->{ref_field}->{table}, [])->text_html;
        push @$tabs, @tab;
    } else {
        my @arr = grep $_ ne $field, @{$tab[0]->{fields}};
        push @answer, _create_inner_join($tab[0], $field->{ref_field}->{table}, $field, $field->{ref_field});
        push @wrong_ans, _create_inner_join(
            $tab[0], $arr_tab[0]->{ref_field}->{table},
            'id_' . rnd->pick(@$tabs[0]->{name}, @$tabs[1]->{name}, @$tabs[2]->{name}), 'id');
        $question = $field->{ref_field}->{table};
        $name_table = $arr[0]->{ref_field}->{table};
        $select = EGE::SQL::Select->new($arr[0]->{ref_field}->{table}, [])->text_html;
        push @$tabs, $tab[0];
    }
    push @wrong_ans, _create_inner_join(
        $arr_tab[0]->{ref_field}->{table}, $_, 'id',
        'id_' . rnd->pick(@$tabs[0]->{name}, @$tabs[1]->{name}, @$tabs[2]->{name})) for $tab[0], $tab[1];
    push @wrong_ans, _create_inner_join($arr_tab[0]->{ref_field}->{table}, $_, 'id', 'id') for @$tabs;
    my $name = rnd->pick(@{$question->{data}});
    my $family_name = @{$question->{fields}}[1] eq 'Фамилия' ? @$name[1] . ' ' . @$name[2] : @$name[1];
    $question->{fields}[0]->{name_alias} = $question->{name};
    my $text = $gen_db->make_text($question, $name_table);
    $self->{text} = sprintf
        "Дан фрагмент базы данных:\n%s\n".
        'Дополните приведенный ниже запрос минимальным набором строк, чтобы он соответствовал вопросу:<br/> «%s %s?» '.
        '<br/>%s <br/> ... <br/> '.
        html->tag('tt', html->cdata('%s')),
        EGE::SQL::Utils::multi_table_html(@$tabs),
        $text->{text},
        $family_name,
        $select,
        EGE::SQL::Query::where_sql({ where =>
            EGE::Prog::make_expr([ '==', $question->{fields}[0], @$name[0]]) });
    $self->variants(map $_->text_html, @answer, @wrong_ans);
    $self->{correct} = [ map $_ <= @answer ? 1 : 0 , 1.. @answer + @wrong_ans];
}

1;
