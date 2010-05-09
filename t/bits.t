use strict;
use warnings;
use utf8;

use Test::More tests => 21;

use lib '..';
use EGE::Bits;

{
    my $b = EGE::Bits->new;
    is $b->get_size, 0, 'empty';
    $b->set_size(6);
    is $b->get_size, 6, 'size';
    is $b->get_bin, '000000', '0 bin';
    is $b->get_oct, '00', '0 oct';
    is $b->get_oct, '00', '0 hex';
    $b->set_bin('1111111');
    is $b->get_bin, '111111', '1 bin size';
}

{
    my $b = EGE::Bits->new->set_bin([1, 0, 1, 0]);
    is $b->get_size, 4, 'set_bin array size';
    is $b->get_bin, '1010', 'set_bin array bin init';
    $b->set_bin([1, 1, 1, 0, 1]);
    is $b->get_bin, '1101', 'set_bin array bin';
}

{
    my $b = EGE::Bits->new->set_bin('1011');
    is $b->get_size, 4, 'set_bin size';
    is $b->get_bin, '1011', 'set_bin bin';
    is $b->get_oct, '13', 'set_bin oct';
    is $b->get_hex, 'B', 'set_bin hex';
}

{
    my $b = EGE::Bits->new->set_oct('76');
    is $b->get_size, 6, 'set_oct size';
    is $b->get_bin, '111110', 'set_oct bin';
    is $b->get_oct, '76', 'set_oct oct';
    is $b->get_hex, '3E', 'set_oct hex';
}

{
    my $b = EGE::Bits->new->set_hex('AC');
    is $b->get_size, 8, 'set_hex size';
    is $b->get_bin, '10101100', 'set_hex bin';
    is $b->get_oct, '254', 'set_hex oct';
    is $b->get_hex, 'AC', 'set_hex hex';
}
