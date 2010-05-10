# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A04;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bin;

sub sum {
    my $av = rnd->in_range(17, 127);
    my $bv = rnd->in_range(17, 127);
    my $r = $av + $bv;
    my ($atext, $btext) = map hex_or_oct($_), $av, $bv;
    my $q = qq~Чему равна сумма чисел <i>a</i> = $atext и <i>b</i> = $btext?~;
    my @errors = rnd->pick_n(3, map $av ^ (1 << $_), 0..7);
    {
        question => $q,
        variants => [ map bin_hex_or_oct($_, rnd->in_range(0, 2)), $r, @errors ],
        answer => 0,
    };
}

1;
