use strict;
use warnings;
use utf8;

use Test::More tests => 3;
use Test::Exception;

use lib '..';
use EGE::Prog::Alg;
use EGE::Prog qw(make_block make_expr);

{
	my %sortings = %EGE::Prog::Alg::sortings;
	for (keys %sortings) {
		my $res = make_block($sortings{$_})->run_val('a', { a => [ 3, 2, 1, 5, 4 ], n => 5 });
	   is join(',', @$res), '1,2,3,4,5', "$_ sorting realization"; 
	}
}