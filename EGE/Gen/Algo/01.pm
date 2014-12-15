# Copyright © 2010-2011 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Algo::Algo01;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::LangTable;

sub algorithm_assimp {
    my ($min_depth, $max_depth) = (2, 5);
    my ($min_op_count, $max_op_count) = (1 , 3);
    my $depth = rnd->in_range($min_depth, $max_depth);

    my $recur_count = 0;
    my $cur_block = ['=', 'S', ['+', 'S', ]]
    for (0..$depth) {
        my $op_count = rnd->in_range($min_tresh, $max_tresh);
        
        for (0..$op_count) {
            $op = rnd->coin;

        }
    }
}

1;