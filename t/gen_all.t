use strict;
use warnings;

use Test::More tests => 4;

use lib '..';

use EGE::Generate;

ok eval { EGE::Generate::all; 1; }, 'EGE';
ok eval { EGE::AsmGenerate::all; 1; }, 'Asm';
ok eval { EGE::DatabaseGenerate::all; 1; }, 'Database';
ok eval { EGE::AlgGenerate::all; 1; }, 'Alg';
