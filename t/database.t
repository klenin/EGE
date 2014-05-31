use strict;
use warnings;
use utf8;

use Test::More tests => 44;
use Test::Exception;

use lib '..';
use EGE::Prog qw(make_expr make_block);
use EGE::SQL::Table;
use EGE::SQL::Queries;

sub pack_table {
    my $self = shift;
    join '|', map join(' ', @$_), $self->{fields}, @{$self->{data}};
}

{
    my $t = EGE::SQL::Table->new([ qw(a b c) ], name => 'table');
    is $t->name, 'table', 'table name';
}

{
    my $tab = EGE::SQL::Table->new([ qw(id name) ]);
    is_deeply $tab->_row_hash([ 2, 3 ]), { id => 2, name => 3 }, 'row hash';
    $tab->insert_rows([ 1, 'aaa' ], [ 2, 'bbb' ]);
    is pack_table($tab->select([ 'id', 'name' ])), 'id name|1 aaa|2 bbb', 'all fields';
    $tab->insert_row(3, 'ccc');
    is pack_table($tab->select([ 'id' ])), 'id|1|2|3', 'field 1';
    is pack_table($tab->select([ 'name' ])), 'name|aaa|bbb|ccc', 'field 2';
    is pack_table($tab->select([ 'id', 'id' ])), 'id id|1 1|2 2|3 3', 'dup field';
    eval { $tab->select([ 'zzz' ]) };
    like $@, qr/zzz/, 'bad field';
}

{
    my $t = EGE::SQL::Table->new([ 'f' ]);
    my $r = 1;
    $t->insert_row($r);
    $r = 2;
    is pack_table($t), 'f|1', 'insert_row copies';
}

{
    my $t = EGE::SQL::Table->new([ 'f' ]);
    my $r = [ 1 ];
    $t->insert_rows($r, $r);
    $r->[0] = 2;
    is pack_table($t), 'f|1|1', 'insert_rows copies';
}

{
    my $tab = EGE::SQL::Table->new([ qw(id name city) ]);
    $tab->insert_rows([ 1, 'aaa', 3 ], [ 2, 'bbb', 2 ],[ 3, 'aac', 1 ], [ 4, 'bbn', 2 ]);
    my $e = make_expr([ '==', 'city', 2 ]);
    is pack_table($tab->where($e)), 'id name city|2 bbb 2|4 bbn 2', 'where city == 2';
    is pack_table($tab->select([ 'id', 'name' ], $e)), 'id name|2 bbb|4 bbn', 'select id, name where city == 2';
    is pack_table($tab->select([], $e)), '||', 'select where sity == 2';
    is $tab->count(), 4, 'count';
    is $tab->where(make_expr(0))->count(), 0, 'where false';
}

{
    my $t = EGE::SQL::Table->new([ 'id' ]);
    $t->insert_rows(map [ $_ ], 1..5);
    my $e = make_expr([ '==', 'id', 3 ]);
    my $w2 = $t->where($e);
    $w2->{data}->[0]->[0] = 9;
    is pack_table($t), 'id|1|2|3|4|5', 'where copy';
    my $w1 = $t->where($e, 1);
    $w1->{data}->[0]->[0] = 9;
    is pack_table($t), 'id|1|2|9|4|5', 'where ref';
}

{
    my $t = EGE::SQL::Table->new([ qw(a b) ]);
    $t->insert_rows([ 1, 2 ], [ 3, 4 ],[ 5, 6 ]);
    $t->update(make_block([ '=', 'a', 'b' ]));
    is pack_table($t), 'a b|2 2|4 4|6 6', 'update var';
    $t->update(make_block([ '=', 'a', ['+', 'a', '1'] ]));
    is pack_table($t), 'a b|3 2|5 4|7 6', 'update expr';
}

{
    my $t = EGE::SQL::Table->new([ qw(a b c) ]);
    $t->insert_rows([ 7, 8, 9 ]);
    $t->update(make_block([ '=', 'c', 'a', '=', 'a', 'b', '=', 'b', 'c' ]));
    is pack_table($t), 'a b c|8 7 7', 'update swap';
}

{
    my $tab = EGE::SQL::Table->new([ qw(id name city) ]);
    $tab->insert_rows([ 1, 'aaa', 3 ], [ 2, 'bbb', 2 ],[ 3, 'aac', 1 ], [ 4, 'bbn', 2 ]);
    $tab->update(make_block([ '=', 'city', sub { $_[0]->{city} == 3 ? 'v' : 'k' } ]));
    is pack_table($tab), 'id name city|1 aaa v|2 bbb k|3 aac k|4 bbn k', 'update sub city';
    $tab->update(make_block([ '=', 'id', sub { $_[0]->{id} > 2 ? 2 : $_[0]->{id} } ]));
    is pack_table($tab), 'id name city|1 aaa v|2 bbb k|2 aac k|2 bbn k', 'update sub id';
}

{
    my $tab1 = EGE::SQL::Table->new([ qw(id city name) ]);
    $tab1->insert_rows([ 2, 'v', 'aaa' ], [ 1, 'k', 'bbb' ], [ 8, 'l', 'ann' ], [ 9, 'k', 'bnn' ]);
    $tab1->delete(make_expr([ '==', 'id', 2 ]));
    is pack_table($tab1), 'id city name|1 k bbb|8 l ann|9 k bnn', 'delete 1';
    $tab1->insert_row(2, 'v', 'aaa');
    $tab1->delete(make_expr([ '>', 'id', 6 ]));
    is pack_table($tab1), 'id city name|1 k bbb|2 v aaa', 'delete 2';
    $tab1->delete(make_expr([ '>=', 'id', 1 ]));
    is pack_table($tab1), 'id city name', 'delete all';
}

{
    my $q = EGE::SQL::Select->new('test', [ qw(a b) ], make_expr [ '<', 'a', 7 ]);
    is $q->text, 'SELECT a, b FROM test WHERE a < 7', 'query text: select where';
}

{
    my $q = EGE::SQL::Select->new('test', [ 'a', make_expr ['+', 'a', 'b'] ]);
    is $q->text, 'SELECT a, a + b FROM test', 'query text: select expr';
}

{
    my $q = EGE::SQL::Select->new('test', []);
    is $q->text, 'SELECT * FROM test', 'query text: select *';
}

{
    my $q = EGE::SQL::Update->new('test', make_block [ '=', 'a', 1, '=', 'x', 'a' ]);
    is $q->text, 'UPDATE test SET a = 1, x = a', 'query text: update';
}

{
    my $q = EGE::SQL::Update->new(EGE::SQL::Table->new([ 'a' ], name => 'nnn'), make_block [ '=', 'a', 1 ]);
    is $q->text, 'UPDATE nnn SET a = 1', 'query text: update named table';
}

{
    my $q = EGE::SQL::Update->new('test',
        make_block([ '=', 'f', [ '-', 'f', 2 ] ]), make_expr [ '>', 'f', '0' ]);
    is $q->text, 'UPDATE test SET f = f - 2 WHERE f > 0', 'query text: update where';
}

{
    my $q = EGE::SQL::Delete->new('test', make_expr [ '>', 'f', '0' ]);
    is $q->text, 'DELETE FROM test WHERE f > 0', 'query text: delete';
}

{
    my $tab =  EGE::SQL::Table->new([ qw(id name n) ], name => 'test');
    my $q = EGE::SQL::Insert->new($tab, [ 'a', 'b', 123 ]);
    is $q->text, q~INSERT INTO test (id, name, n) VALUES ('a', 'b', 123)~, 'query text: insert';
    $q->run();
    is pack_table($tab), 'id name n|a b 123', 'query run: insert';
    throws_ok { EGE::SQL::Insert->new($tab, []); } qr/count/, 'insert field count';
}

{
    my $t1 = EGE::SQL::Table->new([ qw(x y) ]);
    $t1->insert_rows([ 1, 2 ], [ 1, 3 ], [ 1, 4 ]);
    my $t2 = EGE::SQL::Table->new([ qw(z) ]);
    $t2->insert_rows([ 1 ], [ 2 ]);
    my $q = EGE::SQL::Inner_join->new('t1', 't2', $t1, $t2, 'x', 'z' );
    is $q->text, "t1 INNER JOIN t2 ON t1.x = t2.z", 'query text: inner_join';
    my $s = EGE::SQL::Select->new($q, [ 'x' ]);
    is $s->text, "SELECT x FROM t1 INNER JOIN t2 ON t1.x = t2.z", 'query text: select c inner_join'
}

{
    my $q = EGE::SQL::Select->new('test', [ 'id', 'x' ], make_expr [ '<', 'x', 7 ], as => 't');
    my $s = EGE::SQL::Select->new($q, [ 'id' ]);
    is $s->text, "SELECT id FROM (SELECT id, x FROM test WHERE x < 7) AS ", 'query text: subquery select'
}
{
    my $t = EGE::SQL::Table->new([ 'id' ]);
    $t->insert_rows([ 1 ], [ 2 ],[ 3 ], [ 4 ]);
    is pack_table($t->select(['id'], make_expr([ 'between', 'id', 1, 3 ]))), 'id|1|2|3', 'between field 3';
    is pack_table($t->select(['id'], make_expr([ 'between', 'id', 5, 7 ]))), 'id', 'between empty';
    my $q = EGE::SQL::Select->new('test', [ 'id' ], make_expr [ 'between', 'id', 5, 7 ]);
    is $q->text, 'SELECT id FROM test WHERE id BETWEEN 5 AND 7', 'query text: select between';
}

{
    my $t1 = EGE::SQL::Table->new([ qw(id name) ]);
    $t1->insert_rows([ 1, 'aaa' ], [ 2, 'bbb' ], [ 3, 'aac' ], [ 4, 'bbn' ]);
    my $t2 = EGE::SQL::Table->new([ qw(cid city) ]);
    $t2->insert_rows([ 2, 'k' ], [ 1, 'v' ], [ 4, 'j' ], [ 3, 'p' ]);
    is pack_table($t1->inner_join($t2, 'id', 'cid')),
        'id name cid city|1 aaa 1 v|2 bbb 2 k|3 aac 3 p|4 bbn 4 j', 'inner join';

    my $t3 = EGE::SQL::Table->new([ qw(id name) ]);
    $t3->insert_rows([ 5, 'k' ], [ 6, 'v' ], [ 7, 'j' ], [ 8, 'p' ]);
    is pack_table($t3->inner_join($t2, 'id', 'cid')), 'id name cid city', 'inner join empty';
}

{
    my $t1 = EGE::SQL::Table->new([ qw(x y) ]);
    $t1->insert_rows([ 1, 2 ], [ 1, 3 ], [ 1, 4 ]);
    my $t2 = EGE::SQL::Table->new([ qw(z) ]);
    $t2->insert_rows([ 1 ], [ 2 ]);
    is pack_table($t1->inner_join($t2, 'x', 'z')), 'x y z|1 2 1|1 3 1|1 4 1', 'inner join dups';
}

{
    my $tab = EGE::SQL::Table->new([ qw(id name city) ]);
    $tab->insert_rows([ 1, 'a', 3 ], [ 2, 'b', 2 ],[ 3, 'c', 1 ], [ 4, 'd', 2 ]);
    my $f = [ 'id', make_expr([ '+', 'id', 3 ]) ];
    is pack_table($tab->select($f)), 'id expr_1|1 4|2 5|3 6|4 7', 'select expression';
    is pack_table($tab->select($f, make_expr([ '<=', 'id', 3 ]))), 'id expr_1|1 4|2 5|3 6', 'select expression where';
    is pack_table($tab->select([ make_expr sub { $_[0]->{name} . 'x' } ])), 'expr_1|ax|bx|cx|dx', 'select sub';
}

