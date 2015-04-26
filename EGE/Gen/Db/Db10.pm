# Copyright © 2015 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
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
use EGE::SQL::RandomTable;

sub _create_inner_join {
    my ($tab1, $tab2, $field1, $field2) = @_;
    EGE::SQL::Inner_join->new(
        { tab => "", field => $tab1->{name}.".".$field1},
        { tab => $tab2, field => $field2});
}

sub many_inner_join{
    my ($self) = @_;
    my ($tabs, @tables) = rnd->coin() ? EGE::SQL::RandomTable->education_db(): EGE::SQL::RandomTable->product_db();
    my @tab = rnd->pick_n(2, @tables);
    my @answer; my @wrong_ans;
    my @arrs = grep $tab[0]->find_field($_), @{$tab[1]->{fields}};
    my $field = $arrs[0];
    my @arr_tab = grep $_ ne $field, @{$tab[1]->fields};
    my ($question, $name_table, $select);
    push @answer, _create_inner_join(${$tab[0]->{fields}}[0]->{ref_field}->{table}, $tab[0], ${$tab[0]->{fields}}[0]->{ref_field}, ${$tab[0]->{fields}}[0]);
    if (rnd->coin()) {
        push @answer, _create_inner_join($tab[0], $tab[1], $field, $field);
        $question = ${$tab[0]->{fields}}[0]->{ref_field}->{table};
        push @answer, _create_inner_join($tab[1], ${$tab[1]->{fields}}[0]->{ref_field}->{table}, ${$tab[1]->{fields}}[0], ${$tab[1]->{fields}}[0]->{ref_field});
        $name_table = ${$tab[1]->{fields}}[0]->{ref_field}->{table}->{name};
        $select = EGE::SQL::Select->new($question, [])->text_html;
        push @$tabs, @tab;
    } else {
        my @arr = @{$tab[0]->{fields}};
        push @answer, _create_inner_join($tab[0], $arr[1]->{ref_field}->{table}, $arr[1],  $arr[1]->{ref_field});
        push @wrong_ans, _create_inner_join($tab[0], $arr_tab[0]->{ref_field}->{table},
                'id_'.rnd->pick(@$tabs[0]->{name}, @$tabs[1]->{name}, @$tabs[2]->{name}), 'id');
        $question = $field->{ref_field}->{table};
        $name_table = $arr[0]->{ref_field}->{table}->{name};
        $select = EGE::SQL::Select->new($arr[0]->{ref_field}->{table}, [])->text_html;
        push @$tabs, $tab[0];
    }
    push @wrong_ans, _create_inner_join($arr_tab[0]->{ref_field}->{table}, $_, 'id',
        'id_'.rnd->pick(@$tabs[0]->{name}, @$tabs[1]->{name}, @$tabs[2]->{name}))  for $tab[0], $tab[1];
    push @wrong_ans, _create_inner_join($arr_tab[0]->{ref_field}->{table}, $_, 'id', 'id') for @$tabs;
    my $name = rnd->pick(@{$question->{data}});
    my $family_name = @{$question->{fields}}[1] eq 'Фамилия' ? @$name[1].' '.@$name[2] : @$name[1];
    $question->{fields}[0]->{name_alias} = $question->{name};
    $self->{text} = sprintf
        "Дан фрагмент базы данных:\n%s\n".
        'Дополните минимально возможным способом приведенный ниже запрос чтобы он отвечал на вопрос:<br/>'."%s %s?".
        "<br/>%s <br/>" . '... <br/> '.
        html->tag('tt', "%s"),
        EGE::SQL::Utils::multi_table_html(@$tabs),
        $question->{text}->{$name_table},
        $family_name,
        $select,
        EGE::SQL::Query::where_sql({where =>
            EGE::Prog::make_expr([ '==', $question->{fields}[0], @$name[0]])});
    $self->variants(map $_->text_html, @answer, @wrong_ans);
    $self->{correct} = \@answer;
}

1;
