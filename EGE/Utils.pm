# Copyright © 2014 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Utils;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(transpose last_key);

sub transpose {
    @_ or die;
    [ map { my $i = $_; [ map $_->[$i], @_ ]; } 0 .. $#{$_[0]} ];
}

sub last_key {
	my ($hash_ref, $key) = @_;
	defined $hash_ref->{$key} or die "There is not such key: '$key' in hash";
	$key = $hash_ref->{$key} while defined $hash_ref->{$hash_ref->{$key}};
	$key;
}

1;
