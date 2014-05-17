# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::SQL::Utils;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;
use EGE::Utils;
use EGE::SQL::Table;
use EGE::SQL::Queries;

sub create_table {
    my ($row, $col) = @_;
    my $products = EGE::SQL::Table->new( $row);
    my @values = map [ map rnd->in_range(10, 80) * 100, @$col ], 0 .. @$row - 2;
    $products->insert_rows(@{EGE::Utils::transpose( $col, @values)}); 
    $products, @values;
}

1
