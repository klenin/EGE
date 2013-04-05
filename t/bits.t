use strict;
use warnings;
use utf8;

use Test::More tests => 49;

use lib '..';
use EGE::Bits;

{
    my $b = EGE::Bits->new;
    is $b->get_size, 0, 'empty';
    $b->set_size(6);
    is $b->get_size, 6, 'size';
    is $b->is_empty, 1, 'empty is_empty';
    is $b->get_bin, '000000', '0 bin';
    is $b->get_oct, '00', '0 oct';
    is $b->get_oct, '00', '0 hex';
    $b->set_bin('1111111');
    is $b->get_bin, '111111', '1 bin size';
    is $b->is_empty, 0, 'non-empty is_empty';
}

{
    my $b = EGE::Bits->new->set_bin([1, 0, 1, 0]);
    is $b->get_size, 4, 'set_bin array size';
    is $b->get_bin, '1010', 'set_bin array bin init';
    $b->set_bin([1, 1, 1, 0, 1]);
    is $b->get_bin, '1101', 'set_bin array bin';
}

{
    my $b1 = EGE::Bits->new->set_bin('1010');
    my $b2 = EGE::Bits->new->copy($b1);
    is $b2->get_bin, '1010', 'copy';
    $b1->set_bit(0, 1);
    is $b2->get_bin, '1010', 'copy by val';
    $b2->copy($b1, 1);
}

{
    my $b = EGE::Bits->new->set_bin('1011');
    is $b->get_size, 4, 'set_bin size';
    is $b->get_bin, '1011', 'set_bin bin';
    is $b->get_oct, '13', 'set_bin oct';
    is $b->get_hex, 'B', 'set_bin hex';
    is $b->get_dec, 11, 'set_bin dec';
}

{
    my $b = EGE::Bits->new->set_oct('76');
    is $b->get_size, 6, 'set_oct size';
    is $b->get_bin, '111110', 'set_oct bin';
    is $b->get_oct, '76', 'set_oct oct';
    is $b->get_hex, '3E', 'set_oct hex';
    is $b->get_dec, 62, 'set_oct dec';
}

{
    my $b = EGE::Bits->new->set_hex('AC');
    is $b->get_size, 8, 'set_hex size';
    is $b->get_bin, '10101100', 'set_hex bin';
    is $b->get_oct, '254', 'set_hex oct';
    is $b->get_hex, 'AC', 'set_hex hex';
    is $b->get_dec, 172, 'set_hex dec';
}

{
    my $b = EGE::Bits->new->set_size(7)->set_dec(100);
    is $b->get_hex, '64', 'set_dec hex';
    is $b->get_dec, 100, 'set_dec dec';
}

{
    my $b = EGE::Bits->new->set_size(3)->set_dec(3);
    my $ok = 1;
    for (my $i = 4; $ok && $i != 3; $i = ($i + 1) % 8) {
        $b->inc;
        $ok = $b->get_dec == $i;
    }
    ok $ok, 'inc';
}

{
    my $b = EGE::Bits->new->set_bin('0100');
    is $b->get_bit(1), 0, 'get 1';
    is $b->set_bit(1, 1)->get_bit(1), 1, 'set/get 1';
    is $b->get_bit(2), 1, 'get 2';
    is $b->flip(2)->get_bit(2), 0, 'flip 2';
}

{
    my $b = EGE::Bits->new->set_bin('01010111');
    is $b->reverse_->get_bin, '11101010', 'reverse';
}

{
    my $b = EGE::Bits->new->set_bin('01110101');
    is $b->dup->shift_(-1)->get_bin, '11101010', 'shift left';
    is $b->dup->shift_(1)->get_bin, '00111010', 'shift right';
}

{
    my $b = EGE::Bits->new->set_bin('01110000');
    is $b->scan_left(0), 4, 'scan_left 1';
    is $b->scan_left(4), 7, 'scan_left 2';
    is $b->scan_left(7), 8, 'scan_left 3';
}

{
    my $logic_op_test = sub {
        my ($arg1, $op, $arg2) = (shift, shift, shift);
        EGE::Bits->new->set_bin($arg1)->logic_op($op, oct("0b$arg2"), @_)->get_bin;
    };
    is $logic_op_test->('0101', 'and', '1100'), '0100', 'and 1';
    is $logic_op_test->('0101', 'or', '1100'), '1101', 'or 1';
    is $logic_op_test->('0101', 'xor', '1100'), '1001', 'xor 1';
    is $logic_op_test->('0101', 'not', ''), '1010', 'not 1';

    is $logic_op_test->('1111111', 'and', '010', 2, 5), '1101011', 'and 2';
    is $logic_op_test->('0000000', 'or', '101', 1, 4), '0101000', 'or 2';
    is $logic_op_test->('0', 'xor', '1', 0, 1), '1', 'xor 2';
    is $logic_op_test->('0101', 'not', '', 1, 3), '0011', 'not 2';
}

