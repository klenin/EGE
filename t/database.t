use strict;
use warnings;
use utf8;

use Test::More tests => 22;

use lib '..';
use EGE::Prog qw(make_expr);
use EGE::SQL::Table;
use EGE::SQL::Queries;

sub pack_table {
    my $self = shift;
    join '|', map join(' ', @$_), $self->{fields}, @{$self->{data}};
}

{
    my $tab = EGE::SQL::Table->new([ qw(id name) ]);
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
    my $tab = EGE::SQL::Table->new([ qw(id name city) ]);
    $tab->insert_rows([ 1, 'aaa', 3 ], [ 2, 'bbb', 2 ],[ 3, 'aac', 1 ], [ 4, 'bbn', 2 ]);
    $tab->update(['city'], sub { $$_[2] == 3 ? 'v' : 'k' });
    is pack_table($tab), 'id name city|1 aaa v|2 bbb k|3 aac k|4 bbn k', 'update city';
    $tab->update(['id'], sub { $$_[0] > 2 ? 2 : $$_[0] });
    is pack_table($tab), 'id name city|1 aaa v|2 bbb k|2 aac k|2 bbn k', 'update id';
}

{
    my $tab1 = EGE::SQL::Table->new([ qw(id city name) ]); 
    $tab1->insert_rows ([ 2, 'v', 'aaa' ], [ 1, 'k', 'bbb' ], [ 8, 'l', 'ann' ], [ 9, 'k', 'bnn' ]);
    $tab1->delete(make_expr([ '==', 'id', 2 ]));
    is pack_table($tab1), 'id city name|1 k bbb|8 l ann|9 k bnn', 'delete 1';
    $tab1->insert_row (2, 'v', 'aaa');
    $tab1->delete(make_expr([ '>', 'id', 6 ]));
    is pack_table($tab1), 'id city name|1 k bbb|2 v aaa', 'delete 2';
    $tab1->delete(make_expr([ '>=', 'id', 1 ]));
    is pack_table($tab1), 'id city name', 'delete all';
}

{
    my $q = EGE::SQL::Select->new(undef, 'test', [ qw(a b) ], make_expr [ '<', 'a', 7 ]);
    is $q->text, 'SELECT a, b FROM test WHERE a < 7', 'query text: select where';
}

{
    my $q = EGE::SQL::Select->new(undef, 'test', [ 'a', make_expr ['+', 'a', 'b'] ]);
    is $q->text, 'SELECT a, a + b FROM test', 'query text: select expr';
}

{
    my $q = EGE::SQL::Select->new(undef, 'test', []);
    is $q->text, 'SELECT * FROM test', 'query text: select *';
}

