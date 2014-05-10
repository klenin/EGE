use strict;
use warnings;
use utf8;

use Test::More tests => 10;

use lib '..';
use EGE::SQL::Table;
use EGE::Prog;
use EGE::Prog::Lang;

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
    my $tab = EGE::SQL::Table->new([ qw(id name sity) ]); 
    $tab->insert_rows([ 1, 'aaa', 3 ], [ 2, 'bbb', 2 ],[ 3, 'aac', 1 ], [ 4, 'bbn', 2 ]);
    my $e = EGE::Prog::make_expr([ '==', 'sity', 2 ]);
    is pack_table($tab->where($e)), 'id name sity|2 bbb 2|4 bbn 2', 'where sity == 2';
    is pack_table($tab->select([ 'id', 'name'], $e)), 'id name|2 bbb|4 bbn', 'select id, name where sity == 2';
    is pack_table($tab->select([ ], $e)), '||', 'select where sity == 2';
    $tab->update(["sity"], sub { $_[0] == 3?"v":"k"; });
    is pack_table($tab), 'id name sity|1 aaa v|2 bbb k|3 aac k|4 bbn k', 'update field 3';
    is $tab->count(), '4', 'count'; 
}
