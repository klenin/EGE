use strict;
use warnings;

use Test::More tests => 9;

use lib '..';
use EGE::Asm::Processor;

sub set_only {
    my $flags_set = proc->{eflags}->get_set_flags();
    my @set_only = @_;
    my @flags = @{$flags_set->{flags}};
    my @set = @{$flags_set->{set}};
    my $res = 1;
    for my $i (0..$#flags) {
        $res = '' if $flags[$i] ~~ @set_only xor $set[$i];
    }
    $res;
}

{
    proc->run_code([ ['mov', 'al', 98] ]);
    is proc->get_val('eax'), 98, 'mov al';
    proc->run_code([ ['mov', 'ah', 98] ]);
    is proc->get_val('eax'), 25088, 'mov ah';
    proc->run_code([ ['mov', 'al', -56] ]);
    is proc->get_val('eax'), 200, 'mov negative number';
    proc->run_code([ ['mov', 'al', 256] ]);
    is proc->get_val('eax'), 0, 'mov overflow number';
    is set_only(), 1, 'mov set flags';
    proc->run_code([ ['mov', 'ax', 256] ]);
    is proc->get_val('eax'), 256, 'mov ax';
    proc->run_code([ ['mov', 'eax', 256] ]);
    is proc->get_val('eax'), 256, 'mov eax';
}

{
    proc->run_code([ ['mov', 'al', 15], ['add', 'al', 7] ]);
    is proc->get_val('eax'), 22, 'add positive number';
    is set_only(), 1, 'add set flags';
}