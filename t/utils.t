use strict;
use warnings;

use Test::More tests => 5;

use lib '..';
use EGE::Utils qw(transpose);

is_deeply transpose([]), [], 'transpose empty';
is_deeply transpose([ 1 ]), [ [ 1 ] ], 'transpose 1x1';
is_deeply transpose([ 1, 2 ], [ 3, 4 ]), [ [ 1, 3 ], [ 2, 4 ] ], 'transpose 2x2';
is_deeply transpose([ 1, 2, 3 ]), [ [ 1 ], [ 2 ], [ 3 ] ], 'transpose 1x3';
my $x = [ map [ map rand(100), 1..8 ], 1..9 ];
is_deeply transpose(@{transpose(@$x)}), $x, 'double transpose';

