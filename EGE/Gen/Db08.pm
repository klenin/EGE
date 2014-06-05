# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db08;
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

my $parents;

sub names {
    my ($s) = @_;
    my $name;
    if ($s) {
        $name = rnd->pick(@EGE::Russian::Names::male);
    } else {
        $name = rnd->pick(@EGE::Russian::Names::female);
    }
    $name;
}

sub children {
    my ($famile, $id, $sex, $table_persone, $table_kinship) = @_;
    my @ans;
    for my $i (0..rnd->pick(1,2)) {
        my $s = rnd->coin;
        my $id_c = rnd->in_range(500, 3000);
        my $name = $famile;
        $name = rnd->pick(@EGE::Russian::FamilyNames::list) if (!$s);
        $table_kinship->insert_row($id, $id_c);
        $table_persone->insert_row($id_c, $name . ($s ? '' : 'а'), names($s), $s);
        push @ans, $id_c;
    }
    @ans;
}

sub create_table {
    my $table_person = EGE::SQL::Table->new([ qw(id Фамилия Имя Пол) ], name => 'persons');
    my $table_kinship = EGE::SQL::Table->new([ qw(id_parent id_child) ], name => 'kinship');
    my $families = rnd->pick(@EGE::Russian::FamilyNames::list);
    my $sex = rnd->coin;
    my (@grandchildren, @child);
    my $id = rnd->in_range(500, 3000);
    for my $i (0..2) {
        my $s = rnd->coin;
        my $id_c = rnd->in_range(500, 3000);
        my $fam = $families;
        $fam = rnd->pick(@EGE::Russian::FamilyNames::list) if (!$s) ;
        $table_kinship->insert_row($id, $id_c);
        $table_person->insert_row($id_c,  $fam . ($s ? '' : 'а'), names($s), $s);
        push @grandchildren, children($fam, $id_c, $s, $table_person, $table_kinship);
        push @child, $id_c;
    }
    $table_person->insert_row($id, $families . ($sex ? '' : 'а'), names($sex), $sex);
    $parents = $id;
    $table_kinship, $table_person, \@grandchildren, \@child;
}

sub parents {
    my ($self) = @_;
    my ($table_kinship, $table_person, $grandchildren, $child) = create_table();
    my (@requests, $query, $name, $gen);
    my @children = @$child;
    while(1) {
        my ($f1) = rnd->shuffle(@children[1 .. $#children]);
        my $sex = rnd->coin();
        my $inner1 = EGE::SQL::Inner_join->new(
            { tab => $table_kinship, field => 'id_parent' },
            { tab => $table_person, field => 'id' });
        my $inner2 = EGE::SQL::Inner_join->new(
            { tab => $inner1, field => 'id_child', name => 'kinship' },
            { tab => $table_person, field => 'id', as => 'per' });
        my $where = EGE::Prog::make_expr([ '&&',[ '==', 'id_parent', $f1 ],[ '==', 'Пол', \$sex ] ]);
        $query = EGE::SQL::Select->new($inner2, ['Фамилия', 'Имя'], $where);
        my $count = $inner2->run->select(['Фамилия'], $where)->count();
        if ($count) {
            $gen = $sex ? q~сыновья~ : q~дочери~;
            $sex = $sex ? q~'м'~ : q~'ж'~;
            push @requests, EGE::SQL::Select->new($inner1, ['Фамилия', 'Имя'], $where)->text_html;
            my $inner3 = EGE::SQL::Inner_join->new(
                { tab => $table_person, field => 'id_child' },
                { tab => $table_kinship, field => 'id' });
            push @requests, EGE::SQL::Select->new($inner3, ['Фамилия', 'Имя'], $where)->text_html;
            push @requests, EGE::SQL::Select->new($inner2, ['Фамилия', 'Имя'],
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
        "В фрагменте базы данных представлены сведения о родственных отношениях:<table>%s%s</table>\n" .
        'Результатом какого запроса будут %s %s?',
        html->row_n('td', map html->tag('tt', $_->name),  $table_person, $table_kinship),
        html->tag('tr',
            join ('', map(html->td($_->table_html), $table_person, $table_kinship)),
            { html->style('vertical-align' => 'top') }),
            $gen, $name;
    $self->variants($query->text_html, @requests);
}

sub grandchildren{
    my ($self) = @_;
    my ($table_kinship, $table_person, $grandchildren, $child) = create_table();
    my (@requests, $query, $name);
    my $inner1 = EGE::SQL::Inner_join->new(
        { tab => $table_kinship, field => 'id_parent' },
        { tab => $table_person, field => 'id' });
    my $inner2 = EGE::SQL::Inner_join->new(
        { tab => $inner1, field => 'id_child', name => 'kinship' },
        { tab => $table_person, field => 'id', as => 'per' });
    my $where = EGE::Prog::make_expr([ '!=', 'id_parent', $parents ]);
    $query = EGE::SQL::Select->new($inner2, ['Фамилия'], $where);
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
    push @requests, EGE::SQL::Select->new($inner1, ['Фамилия'], $where)->text_html;
    my $inner3 = EGE::SQL::Inner_join->new(
        { tab => $table_person, field => 'id_child' },
        { tab => $table_kinship, field => 'id' });
    push @requests, EGE::SQL::Select->new($inner3, ['Фамилия'], $where)->text_html;
    push @requests, EGE::SQL::Select->new($inner2, ['Фамилия'],
        EGE::Prog::make_expr([ '==', 'id_parent', $parents ]))->text_html;
    $table_person->update(EGE::Prog::make_block [ '=', 'Пол', sub { $_[0]->{'Пол'} ? 'м' : 'ж' } ]);
    $self->{text} = sprintf
        "В фрагменте базы данных представлены сведения о родственных отношениях:<table>%s%s</table>\n" .
        'Результатом какого запроса будут внуки %s ?',
        html->row_n('td', map html->tag('tt', $_->name),  $table_person, $table_kinship),
        html->tag('tr',
            join ('', map(html->td($_->table_html), $table_person, $table_kinship)),
            { html->style('vertical-align' => 'top') }),
            $name;
    $self->variants($query->text_html, @requests);
}

sub nuncle {
    my ($self) = @_;
    my ($table_kinship, $table_person, $grandchildren, $child) = create_table();
    my (@requests, $query, $name);
    my @grand = @$grandchildren;
    my ($f1) = rnd->shuffle(@grand[1 .. $#grand]);
    my $where = EGE::Prog::make_expr([ '==', 'id_child', $f1 ]);
    $query = EGE::SQL::Select->new($table_kinship, ['id_parent'], $where, as => 'person1');
    my $tab = $query->run;
    my $inner2 = EGE::SQL::Inner_join->new(
        { tab => $query, field => 'id_parent' },
        { tab => $table_kinship, field => 'id_child', as => 'k1' });
    my $inner4 = EGE::SQL::Inner_join->new(
        { tab => $inner2, field => 'id_parent', name => 'k1' },
        { tab => $table_kinship, field => 'id_parent', as => 'k2' });
    my $inner5 = EGE::SQL::Inner_join->new(
        { tab => $inner4, field => 'id_parent', name => 'k2' },
        { tab => $table_person, field => 'id' });
    my $query2 = EGE::SQL::Select->new($inner5, [ 'Фамилия', 'Имя' ]);
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
    push @requests, EGE::SQL::Select->new($inner2, ['Фамилия', 'Имя'], $where)->text_html;
    push @requests, EGE::SQL::Select->new($inner4, ['Фамилия'], $where)->text_html;
    push @requests, EGE::SQL::Select->new($table_person, ['Фамилия', 'Имя'],
        EGE::Prog::make_expr([ '==', 'id_parent', $parents ]))->text_html;
    $table_person->update(EGE::Prog::make_block [ '=', 'Пол', sub { $_[0]->{'Пол'} ? 'м' : 'ж' } ]);
    $self->{text} = sprintf
        "В фрагменте базы данных представлены сведения о родственных отношениях:<table>%s%s</table>\n" .
        'Результатом какого запроса будут родители %s, их сестеры и братья?',
        html->row_n('td', map html->tag('tt', $_->name),  $table_person, $table_kinship),
        html->tag('tr',
            join ('', map(html->td($_->table_html), $table_person, $table_kinship)),
            { html->style('vertical-align' => 'top') }),
            $name;
    $self->variants($query2->text_html, @requests);
}

1;
