use strict;
use warnings;

use Test::More tests => 4;

use lib '..';

use EGE::Generate;

$EGE::GenerateBase::test = sub { isa_ok $_[0], 'EGE::GenBase', $_[0]->{method}; };

subtest EGE => sub { EGE::Generate::all; done_testing; };
subtest Asm => sub { EGE::AsmGenerate::all; done_testing; };
subtest Database => sub { EGE::DatabaseGenerate::all; done_testing; };
subtest Alg => sub { EGE::AlgGenerate::all; done_testing; };
