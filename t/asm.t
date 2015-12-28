use strict;
use warnings;

use Test::More tests => 4;

use lib '..';
use EGE::Asm::AsmCodeGenerate;

{
    is cgen->format_command([ 'mov', 'ax', 65536 ], '%d'), 'mov ax, 65536';
    is cgen->format_command([ 'mov', 'ax', 65535 ], '%04xh'), 'mov ax, 0ffffh';
    is cgen->format_command([ 'mov', 'ax', 32767 ], '%04xh'), 'mov ax, 7fffh';
}

{
    is EGE::Asm::AsmCodeGenerate::make_reg(16, 'c'), 'cx';
}

