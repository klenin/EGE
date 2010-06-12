use strict;
use warnings;
use utf8;

use Test::More tests => 9;

use lib '..';
use EGE::NotationBase qw(base_to_dec dec_to_base);

is base_to_dec(10, 39058), 39058, 'base_to_dec 10';
is base_to_dec(2, 1111), 15, 'base_to_dec 2';
is base_to_dec(36, 'az'), 10 * 36 + 35, 'base_to_dec az';
is base_to_dec(36, 'ZA'), 35 * 36 + 10, 'base_to_dec ZA';

eval { base_to_dec(5, '?'); };
like($@, qr/^\?/, 'bad digit');
eval { base_to_dec(5, 12345); };
like($@, qr/^5/, 'bad digit');

is dec_to_base(10, 92384), 92384, 'dec_to_base 10';
is dec_to_base(2, 31), '11111', 'dec_to_base 2';
is dec_to_base(36, 10 * 36 + 35), 'AZ', , 'dec_to_base AZ';
