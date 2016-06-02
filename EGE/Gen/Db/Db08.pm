# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Db::Db08;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::SQL::Table;
use EGE::SQL::Queries;
use EGE::SQL::Utils;

my ($parents, @males, @females);

sub make_person {
    my ($family_name, $table_persons, $new_family_name) = @_;
    my $is_male = rnd->coin;
    my $person_id = rnd->in_range_except(1000, 4000, $table_persons->column_array('id'));
    if ($new_family_name) {
        $family_name = $$new_family_name =
            $is_male ? $family_name : rnd->pick(@EGE::Russian::FamilyNames::list);
    }
    $table_persons->insert_row(
        $person_id, $family_name . ($is_male ? '' : 'а'), $is_male ? shift @males : shift @females, $is_male);
    $person_id;
}

sub children {
    my ($family_name, $parent_id, $table_persons, $table_kinship) = @_;
    map {
        my $child_id = make_person($family_name, $table_persons, \my $nf);
        $table_kinship->insert_row($parent_id, $child_id);
        $child_id;
    } 0 .. rnd->in_range(1, 2);
}

sub create_table {
    my $table_persons = EGE::SQL::Table->new([ qw(id Фамилия Имя Пол) ], name => 'persons');
    my $table_kinship = EGE::SQL::Table->new([ qw(id_parent id_child) ], name => 'kinship');
    @males = EGE::Russian::Names::different_males(10);
    @females = EGE::Russian::Names::different_females(10);
    my (@grandchildren, @children);
    my $family_name = rnd->pick(@EGE::Russian::FamilyNames::list);
    my $id = make_person($family_name, $table_persons);
    for (0 .. 2) {
        my ($child_id) = make_person($family_name, $table_persons, \my $new_family_name);
        $table_kinship->insert_row($id, $child_id);
        push @grandchildren, children($new_family_name, $child_id, $table_persons, $table_kinship);
        push @children, $child_id;
    }
    $parents = $id;
    $table_kinship, $table_persons, \@grandchildren, \@children;
}

sub parents {
    my ($self) = @_;
    my ($table_kinship, $table_person, $grandchildren, $child) = create_table();
    my (@requests, $query, $name, $gen);
    my @children = @$child;
    while(1) {
        my ($f1) = rnd->shuffle(@children[1 .. $#children]);
        my $sex = rnd->coin();
        my $inner1 = EGE::SQL::InnerJoin->new(
            { tab => $table_kinship, field => 'id_parent' },
            { tab => $table_person, field => 'id' });
        my $inner2 = EGE::SQL::InnerJoin->new(
            { tab => $inner1, field => 'id_child' },
            { tab => EGE::SQL::SubqueryAlias->new($table_person, 'per'), field => 'id' });
        my $where = EGE::Prog::make_expr([ '&&',[ '==', EGE::Prog::Field->new({name =>'id_parent', name_alias => 'kinship'}), $f1 ],
            [ '==', EGE::Prog::Field->new({name =>'Пол', name_alias => 'per'}), \$sex ] ]);
        my $query_fields = [EGE::Prog::Field->new({name =>'Фамилия', name_alias => 'per'}),
                EGE::Prog::Field->new({name => 'Имя', name_alias => 'per'})];
        $query = EGE::SQL::Select->new($inner2, $query_fields , $where);
        my $count = $inner2->run->select(['Фамилия'], $where)->count();
        if ($count) {
            $gen = $sex ? q~сыновья~ : q~дочери~;
            $sex = $sex ? q~'м'~ : q~'ж'~;
            push @requests, EGE::SQL::Select->new($inner1, $query_fields, $where)->text_html;
            my $inner3 = EGE::SQL::InnerJoin->new(
                { tab => $table_person, field => 'id_child' },
                { tab => $table_kinship, field => 'id' });
            push @requests, EGE::SQL::Select->new($inner3, $query_fields, $where)->text_html;
            push @requests, EGE::SQL::Select->new($inner2, $query_fields,
                EGE::Prog::make_expr( ['||',[ '==', 'id_parent', $f1 ],[ '==', 'Пол', \$sex ] ]))->text_html;
            my $par = ${$table_person->select(['Фамилия', 'Имя', 'Пол'],
                EGE::Prog::make_expr(['==', 'id', $f1]))->{data}}[0];
            $name = @$par[0];
            if (!@$par[2]) {
                $name = substr($name, 0, -1);
                $name .= q~ой~;
            } else {
                $name .=  q~а~;
            }
            $name .= " " . substr(@$par[1], 0, 1) . ".";
            last;
        }
    }
    $table_person->update(EGE::Prog::make_block [ '=', 'Пол', sub { $_[0]->{'Пол'} ? 'м' : 'ж' } ]);
    $self->{text} = sprintf
        "В фрагменте базы данных представлены сведения о родственных отношениях:\n%s\n" .
        'Результатом какого запроса будут %s %s?',
        EGE::SQL::Utils::multi_table_html($table_person, $table_kinship), $gen, $name;
    $self->variants($query->text_html, @requests);
}

sub grandchildren {
    my ($self) = @_;
    my ($table_kinship, $table_person, $grandchildren, $child) = create_table();
    my (@requests, $query, $name);
    my $inner1 = EGE::SQL::InnerJoin->new(
        { tab => $table_kinship, field => 'id_parent' },
        { tab => $table_person, field => 'id' });
    my $inner2 = EGE::SQL::InnerJoin->new(
        { tab => $inner1, field => 'id_child' },
        { tab => EGE::SQL::SubqueryAlias->new($table_person, 'per'), field => 'id' });
    my $where = EGE::Prog::make_expr([ '!=', EGE::Prog::Field->new({name =>'id_parent', name_alias => 'kinship'}), $parents ]);
    my $query_fields = [EGE::Prog::Field->new({name =>'Фамилия', name_alias => 'per'})];
    $query = EGE::SQL::Select->new($inner2, $query_fields, $where);
    my $par = ${$table_person->select(['Фамилия', 'Имя', 'Пол'],
        EGE::Prog::make_expr(['==', 'id', $parents]))->{data}}[0];
    $name = @$par[0];
    if (!@$par[2]) {
        $name = substr($name, 0, -1);
        $name .= q~ой~;
    } else {
        $name .=  q~а~;
    }
    $name .= " " . substr(@$par[1], 0, 1) . ".";
    push @requests, EGE::SQL::Select->new($inner1, $query_fields, $where)->text_html;
    my $inner3 = EGE::SQL::InnerJoin->new(
        { tab => $table_person, field => 'id_child' },
        { tab => $table_kinship, field => 'id' });
    push @requests, EGE::SQL::Select->new($inner3, $query_fields, $where)->text_html;
    push @requests, EGE::SQL::Select->new($inner2, $query_fields,
        EGE::Prog::make_expr([ '==', 'id_parent', $parents ]))->text_html;
    $table_person->update(EGE::Prog::make_block [ '=', 'Пол', sub { $_[0]->{'Пол'} ? 'м' : 'ж' } ]);
    $self->{text} = sprintf
        "В фрагменте базы данных представлены сведения о родственных отношениях:\n%s\n" .
        'Результатом какого запроса будут внуки %s?',
        EGE::SQL::Utils::multi_table_html($table_person, $table_kinship), $name;
    $self->variants($query->text_html, @requests);
}

sub nuncle {
    my ($self) = @_;
    my ($table_kinship, $table_person, $grandchildren, $child) = create_table();
    my (@requests, $query, $name);
    my @grand = @$grandchildren;
    my ($f1) = rnd->shuffle(@grand[1 .. $#grand]);
    my $where = EGE::Prog::make_expr([ '==', 'id_child', $f1 ]);
    $query = EGE::SQL::SubqueryAlias->new(
        EGE::SQL::Select->new($table_kinship, ['id_parent'], $where), 'person1');
    my $tab = $query->run;
    my $inner2 = EGE::SQL::InnerJoin->new(
        { tab => $query, field => 'id_parent' },
        { tab => EGE::SQL::SubqueryAlias->new($table_kinship, 'k1'), field => 'id_child' });
    my $inner4 = EGE::SQL::InnerJoin->new(
        { tab => $inner2, field => 'k1.id_parent' },
        { tab => EGE::SQL::SubqueryAlias->new($table_kinship, 'k2'), field => 'id_parent' });
    my $inner5 = EGE::SQL::InnerJoin->new(
        { tab => $inner4, field => 'k2.id_child' },
        { tab => $table_person, field => 'id' });
    my $query_fields = [EGE::Prog::Field->new({name =>'Фамилия'}),
                EGE::Prog::Field->new({name => 'Имя'})];
    my $query2 = EGE::SQL::Select->new($inner5, $query_fields);
    my $par = ${$table_person->select(['Фамилия', 'Имя', 'Пол'],
        EGE::Prog::make_expr(['==', 'id', $f1]))->{data}}[0];
    $name = @$par[0];
    if (!@$par[2]) {
        $name = substr($name, 0, -1);
        $name .= q~ой~;
    } else {
        $name .=  q~а~;
    }
    $name .= " " . substr(@$par[1], 0, 1) . ".";
    push @requests, EGE::SQL::Select->new($inner2, $query_fields, $where)->text_html;
    push @requests, EGE::SQL::Select->new($inner4, $query_fields, $where)->text_html;
    push @requests, EGE::SQL::Select->new($table_person, $query_fields,
        EGE::Prog::make_expr([ '==', 'id_parent', $parents ]))->text_html;
    $table_person->update(EGE::Prog::make_block [ '=', 'Пол', sub { $_[0]->{'Пол'} ? 'м' : 'ж' } ]);
    $self->{text} = sprintf
        "В фрагменте базы данных представлены сведения о родственных отношениях:\n%s\n" .
        'Результатом какого запроса будут родители %s, их сестры и братья?',
        EGE::SQL::Utils::multi_table_html($table_person, $table_kinship), $name;
    $self->variants($query2->text_html, @requests);
}

1;
