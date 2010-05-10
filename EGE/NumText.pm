# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::NumText;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(num_text num_bits num_bytes bits_and_bytes);

sub num_text {
    my ($n, $ts) = @_;
    my $d = $n % 10;
    my $t =
        10 <= $n && $n <= 20 ? 2 :
        $d == 1 ? 0 :
        $d =~ /^2|3|4$/ ? 1 :
        2;
   "$n $ts->[$t]";
};

sub num_bits { num_text($_[0], [ 'бит', 'бита', 'бит' ]) }
sub num_bytes { num_text($_[0], [ 'байт', 'байта', 'байтов' ]) }

sub bits_and_bytes { num_bytes($_[0]), num_bits($_[0] * 8) }

1;
