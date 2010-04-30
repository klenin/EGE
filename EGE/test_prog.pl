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
=begin
$b->run($env);

print $b->to_lang('Pascal'), "\n";
print %$env;
print ' ops=', $b->count_ops, "\n";

$env = { _skip => rnd->in_range(1, $b->count_ops) };
$b->run($env);
print %$env;
=cut

my $b1 = EGE::Prog::make_block([
    '=', 'x', ['+', 4, ['*', 8, 3]],
    '=', 'y', ['+', ['%', 'x', 10], 15],
    '=', 'x', ['+', ['//', 'y', 10], 3],
    '#', { Basic => '\' comment', Pascal => '{comment}' },
]);

print $b1->to_lang('Pascal'), "\n";
$b1->run($env);
print "\n", %$env;
$env = { _replace_op => { '%' => '//' } };
$b1->run($env);
print "\n", %$env;
