use strict;
use warnings;

use Test::More tests => 18;
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
    is $g->edges_string, '{1->{2},2->{1,3},3->{}}', 'edges_string';
    $g->edge1(3, 2, 7);
    is $g->is_oriented, 0, 'not oriented';
    is $g->edges_string, '{1->{2},2->{1,3},3->{2:7}}', 'edges_string weight';
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

{
    my $g = EGE::Graph->new(vertices => { 1 => {}, 2 => {}, 3 => {}, 4 => {} });
    $g->edge1(1, 2);
    $g->edge1(2, 3);
    $g->edge1(3, 4);
    my $cache = {};
    is $g->count_paths(1, 4, $cache), 1, 'count_paths 1';
    $g->edge1(2, 4);
    is $g->count_paths(1, 4, $cache), 1, 'count_paths cache';
    is $g->count_paths(1, 4), 2, 'count_paths 2';
}

{
    my $g = EGE::Graph->new(vertices => { map { $_ => {} } 0..30 });
    for (0..9) {
      my $v = 3 * $_;
      $g->edge1($v, $v + 1);
      $g->edge1($v, $v + 2);
      $g->edge1($v + 1, $v + 3);
      $g->edge1($v + 2, $v + 3);
    }
    is $g->count_paths(0, 30), 1024, 'count_paths 2^n';
}

{
    my $g = EGE::Graph->new(vertices => { A => {}, B => {} });
    $g->edge1('B', 'A', 7);
    my $old_str = $g->edges_string;
    is $g->html_matrix, join("\n",
      '<table border="1"><tr><td></td><td>A</td><td>B</td></tr>',
      '<tr><td>A</td><td> </td><td> </td></tr>',
      '<tr><td>B</td><td>7</td><td> </td></tr>',
      '</table>'), 'html_matrix';
    is $g->edges_string, $old_str, 'html_matrix preserves graph'
}
