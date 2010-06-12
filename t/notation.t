use strict;
use warnings;
use utf8;

use Test::More tests => 6;

use lib '..';
use EGE::NotationBase qw(base_to_dec);

is base_to_dec(10, 39058), 39058, 'base_to_dec 10';
is base_to_dec(2, 1111), 15, 'base_to_dec 2';
is base_to_dec(36, 'az'), 10 * 36 + 35, 'base_to_dec az';
is base_to_dec(36, 'ZA'), 35 * 36 + 10, 'base_to_dec ZA';

eval { base_to_dec(5, '?'); };
like($@, qr/^\?/, 'bad digit');
eval { base_to_dec(5, 12345); };
like($@, qr/^5/, 'bad digit');
