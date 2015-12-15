use strict;
use warnings;

use Test::More tests => 4;

use lib '..';

use EGE::Generate;

$EGE::GenerateBase::test = sub { isa_ok $_[0], 'EGE::GenBase', $_[0]->{method}; };

subtest EGE => \&EGE::Generate::all;
subtest Asm => \&EGE::AsmGenerate::all;
subtest Database => \&EGE::DatabaseGenerate::all;
subtest Alg => \&EGE::AlgGenerate::all;
