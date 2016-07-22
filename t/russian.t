use strict;
use warnings;
use utf8;

use Test::More tests => 12;

use lib '..';
use EGE::Russian::Names qw(different);
use EGE::Russian::SimpleNames qw(genitive);

{
    my %h; undef @h{@EGE::Russian::alphabet};
    is scalar keys %h, 33, 'alphabet';
}

for (1..5) {
    my ($n1, $n2) = EGE::Russian::Names::different_males(2);
    isnt substr($n1, 0, 1), substr($n2, 0, 1), "different_males $_";
}

for (1..5) {
    my ($n1, $n2) = EGE::Russian::Names::different_names(2);
    isnt substr($n1->{name}, 0, 1), substr($n2->{name}, 0, 1), "different_names $_";
}

is genitive('Вий'), 'Вия', 'SimpleNames::genitive';
