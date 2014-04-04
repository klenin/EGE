use strict;
use warnings;

use Test::More tests => 3;

use lib '..';
use EGE::SQL::Table;
use utf8;

sub check {
    my $self = shift;
    my $res = "";
    for ($self->{fields}, @{$self->{data}}){  
      $res = join (" ", $res, @$_);
    }
    $res;
 }

{
    my $tab = EGE::SQL::Table->new([ qw(id name) ]);
    $tab->insert_row(1, 'aaa');
    $tab->insert_row(2, 'bbb');
    $tab->insert_row(3, 'ccc');
    is check($tab->select([ "id", "name" ])), " id name 1 aaa 2 bbb 3 ccc";
    is check($tab->select([ "id" ])), " id 1 2 3";
    is check($tab->select([ "name" ])), " name aaa bbb ccc";
}

