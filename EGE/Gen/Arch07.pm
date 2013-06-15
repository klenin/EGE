# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch07;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub loop_number {
    my $self = shift;
    cgen->clear;
    my ($reg, $reg2) = cgen->get_regs(8, 8);
    my $arg = rnd->pick(1..126, 128..254);
    my $label = 'L';
    my $jmp = 'j' . rnd->pick(qw(p o s nc np nz no ns));
    $jmp = 'jns' if $jmp eq 'js' && $arg < 128;
    $jmp = 'js' if $jmp eq 'jns' && $arg >= 128;
    cgen->add_commands(
        [ 'mov', $reg, $arg ],
        [ "$label:" ],
        [ 'add', $reg, 1 ],
        [ $jmp, $label ],
    );
    my $code_txt = cgen->get_code_txt('%s');
    $self->{text} =
        "При выполнении кода $code_txt в команда " .
        "<code>add $reg, 1</code> будет выполнена раз:";
    my $inf = 'бесконечное число (программа зациклится)';
    if ($jmp eq 'jp' || $jmp eq 'jnp') {
        $self->variants(1, 2, 3, $inf);
        if ($reg =~ m/^[a-d]h$/) {
            $self->{correct} = $jmp eq 'jp' ? 3 : 0;
        }
        else {
            cgen->add_command('add', $reg2, 1);
            cgen->move_command(4, 2);
            $self->{correct} = proc->run_code(cgen->{code})->get_val($reg2) - 1;
        }
    }
    elsif ($jmp eq 'jo') {
        $self->variants(1, 256 - $arg, (128 - $arg + 256) % 256, $inf);
    }
    else {
        my $res =
            $jmp eq 'jnc' || $jmp eq 'jnz' || $jmp eq 'js' ? 256 - $arg :
            $jmp eq 'jno' && $arg < 128 || $jmp eq 'jns' ? 128 - $arg :
            $jmp eq 'jno' && $arg >= 128 ? 256 - $arg + 128 : '';
        my $res1 = $res == 2 ? 3 : rnd->pick($res + 1, $res - 1);
        $self->variants($res, $res1, 1, $inf);
	}
}

1;
