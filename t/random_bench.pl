use strict;
use warnings;

use Benchmark qw(:all);

use lib '..';
use EGE::Random;

my $rndb = EGE::Random->new(gen => 'Builtin');
my $rnd32 = EGE::Random->new(gen => 'PCG_XSH_RR_64_32_BigInt');

cmpthese(100_000, {
    'rand' => sub { $rndb->in_range(0, 999) },
    'EGE 64' => sub { rnd->in_range(0, 999) },
    'EGE 32' => sub { $rnd32->in_range(0, 999) },
});

