use strict;
use warnings;

use Test::More tests => 5;

use lib '..';
use EGE::Russian::Names qw(different);

for (1..5) {
    my ($n1, $n2) = EGE::Russian::Names::different_males(2);
    isnt substr($n1, 0, 1), substr($n2, 0, 1), "different_males $_";
}
