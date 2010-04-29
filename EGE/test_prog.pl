use strict;
use warnings;

use lib '..';

use Carp;
$SIG{__WARN__} = sub { Carp::confess @_ };
$SIG{__DIE__} = sub { Carp::confess @_ };

use Data::Dumper;

use EGE::Prog;
use EGE::Random;

my $m = 4;

my $b = EGE::Prog::make_block([
    '=', 'a', 2,
    '=', 'b', ['+', 'a', 4],
    '=', 'b', ['-', 1, 'b'],
    '=', 'c', ['+', ['-', 'b'], ['*', \$m, 'a']],
]);

my $env = {};

#print Dumper($b);
$b->run($env);

print $b->to_lang('Pascal'), "\n";
print %$env;
print ' ops=', $b->count_ops, "\n";

$env = { _skip => rnd->in_range(1, $b->count_ops) };
$b->run($env);
print %$env;
