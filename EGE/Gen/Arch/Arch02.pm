# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch::Arch02;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

BEGIN {
    no strict 'refs';
    for my $type (qw(add logic shift)) {
        *{"flags_value_$type"} = sub { $_[0]->flags_value($type); };
    }
}

sub flags_value {
    my ($self, $type) = @_;
    my $format;
    do {
        (undef, $format) = cgen->generate_simple_code($type);
        proc->run_code(cgen->{code});
    } until grep $_, values %{proc->{eflags}};

    my $code_txt = cgen->get_code_txt($format);
    $self->{text} = "В результате выполнения кода $code_txt будут установлены флаги:";
    $self->variants(keys %{proc->{eflags}});
    $self->{correct} = [ values %{proc->{eflags}} ];
}

1;
