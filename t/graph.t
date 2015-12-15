use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

use lib '..';

use EGE::Graph;

{
    my $g = EGE::Graph->new(vertices => { 1 => {}, 2 => {}, 3 => {} });
    is_deeply [ sort $g->vertex_names ], [ 1, 2, 3 ], 'vertex names';

    throws_ok { $g->edge1(3, 4) } qr/4/, 'bad vertex 1 ';
    throws_ok { $g->edge2(3, 4) } qr/4/, 'bad vertex 2';

    $g->edge1(1, 2);
    $g->edge1(2, 1);
    $g->edge1(2, 3);
    is $g->is_oriented, 1, 'oriented';
    $g->edge1(3, 2);
    is $g->is_oriented, 0, 'not oriented';
}

{
    my $g = EGE::Graph->new(vertices => { A => { at => [ 10, 40 ] }, B => { at => [ 20, 30 ] } });
    is_deeply $g->bounding_box, [ 10, 30, 20, 40 ], 'bounding_box';
}

{
    is_deeply EGE::Graph::add([ 1, 2, 3 ], [ 4, 5, 6 ]), [ 5, 7, 9 ], 'add';
    is_deeply EGE::Graph::size([ 1, 2, 3, 5 ]), [ 1, 2, 2, 3 ], 'size';
}

{
    my $g = EGE::Graph->new(vertices => { 1 => {}, 2 => {}, 3 => {} });
    $g->edge2(1, 2);
    ok !$g->is_connected, 'not connected';
    $g->edge2(3, 2);
    ok $g->is_connected, 'connected';
}
