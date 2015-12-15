use strict;
use warnings;

use Test::More tests => 5;
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
