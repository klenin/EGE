# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch03;
use base 'EGE::GenBase::MultipleChoiceFixedVariants';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub choose_commands_mod_3 {
    my $self = shift;
    my $reg = cgen->get_reg(8);
    my ($jmp, $arg) = @{rnd->pick(
        [ jnc => rnd->in_range(0, 41) * 6 + 3 ],
        [ jns => rnd->in_range(0, 20) * 6 + 1 ],
        [ js => rnd->in_range(21, 41) * 6 + 3 ],
    )};
    my $label = 'L';
    (my $val_add, $self->{correct}) = @{rnd->pick(
        [ 1 => [ 1, 1, 1, 0, 1 ] ],
        [ 2 => [ 1, 1, 0, 1, 1 ] ],
        [ 3 => [ 1, 1, 1, 1, 1 ] ],
    )};
    cgen->set_commands(
        [ 'mov', $reg, $arg ],
        [ "$label:" ],
        [ 'add', $reg, $val_add ],
        [ $jmp, $label ]);
    $self->formated_variants('<code>%s</code>',
        "mov $reg, $arg",
        "$label:",
        "add $reg, 1",
        "add $reg, 2",
        "$jmp $label");
    $self->{text} =
        'Выделите команды, которые следует оставить в программе, ' .
        "чтобы после выполнения полученного кода в регистре $reg содержалось значение " .
        proc->run_code(cgen->{code})->get_val($reg);
}

1;
