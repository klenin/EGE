# Copyright © 2014 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Utils;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(transpose);

sub transpose {
    @_ or die;
    [ map { my $i = $_; [ map $_->[$i], @_ ]; } 0 .. $#{$_[0]} ];
}

1;

