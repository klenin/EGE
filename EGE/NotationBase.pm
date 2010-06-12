# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::NotationBase;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(base_to_dec);

sub base_to_dec {
    my ($base, $number) = @_;
    my $r = 0;
    for (split //, $number) {
        my $digit = ord($_) - (
            /[0-9]/ ? ord('0') :
            /[a-z]/ ? ord('a') - 10 :
            /[A-Z]/ ? ord('A') - 10 : die $_);
        die $_ if $digit >= $base;
        $r = $r * $base + $digit;
    }
    $r;
}

1;
