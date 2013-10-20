# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch06;
use base 'EGE::GenBase::Match';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub random_byte {
    my ($x, $y) = rnd->shuffle(rnd->pick(0, 15), rnd->in_range(1, 14));
    $x * 16 + $y;
}

sub try_match_values {
    my $self = shift;
    my ($a, $b) = rnd->pick_n(2, qw(a b c d));
    my @regs8 = ($a . 'l', $a . 'h', $b . 'l', $b . 'h');
    my @regs16 = ($a . 'x', $b . 'x');
    cgen->clear;
    cgen->add_commands(
        map([ 'mov', $_, random_byte() * 256 + random_byte() ], @regs16),
        [ rnd->pick(qw(shl shr sal sar rol ror)), rnd->pick(@regs8), 4 ],
        [ rnd->pick(qw(and or xor)), rnd->pick_n(2, @regs8) ],
        [ rnd->pick(qw(add sub adc sbb)), rnd->shuffle(@regs16) ],
    );
    proc->run_code(cgen->{code});
    my @vals = map proc->get_val($_), @regs8;
    return if @vals != keys %{{ map { $_ => 1 } @vals }};

    my $code_txt = cgen->get_code_txt('%04Xh');
    $self->{text} =
        "Процессором был выполнен следующий код: $code_txt " .
        'Установить соответствие между регистрами и полученными в них значениями';
    $self->{left_column} = \@regs8;
    $self->formated_variants('%02Xh', @vals);
    $self->{correct} = [ 0, 1, 2, 3 ];
}

sub match_values { 1 until $_[0]->try_match_values; }

1;
