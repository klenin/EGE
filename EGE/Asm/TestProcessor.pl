# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE

use strict;
use warnings;

use lib '../..';

use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

my $fname = shift;
open(INFILE, $fname);
my $line;
while ($line = <INFILE>) {
	my @arr = split " ", $line;
	cgen->add_command(@arr);	
}
close(INFILE);

proc->run_code(cgen->{code});
proc->print_state();
