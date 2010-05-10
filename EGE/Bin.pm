# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Bin;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(hex_or_oct to_bin bin_hex_or_oct);

sub to_bin {
    my $r = unpack 'B32', pack 'N', $_[0];
    $r =~ s/^0+//;
    $r;
}

sub bin_text { to_bin($_[0]) . '<sub>2</sub>' }

sub oct_text { sprintf '%o<sub>8</sub>', $_[0] }

sub hex_text { sprintf '%X<sub>16</sub>', $_[0] }

sub hex_or_oct { $_[1] ? hex_text($_[0]) : oct_text($_[0]) }
sub bin_hex_or_oct { [ \&bin_text, \&oct_text, \&hex_text ]->[$_[1]]->($_[0]); }

1;
