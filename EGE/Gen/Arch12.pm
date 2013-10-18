# Copyright © 2013 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Arch12;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::AsmCodeGenerate;

sub cartesian_join {
    my ($sep, $set1, $set2) = @_;
    my @result;
    for my $v1 (@$set1) {
        for my $v2 (@$set2) {
            push @result, "$v1$sep$v2";
        }
    }
    @result;
}

sub cond_max_min {
    my $self = shift;
    my ($reg1, $reg2, $reg3) = cgen->get_regs((rnd->pick(16, 32)) x 3);
    my @ccs = (
        cartesian_join('', [ '', 'n' ], [ qw(g l ge le) ]),
        cartesian_join('', [ '', 'n' ], [ qw(a b ae be) ]));
    my $i = rnd->in_range(0, $#ccs);
    my $signed = $i >= 4 ? 1 : 0;
    my $swap = rnd->coin;
    my $min = ($i + $swap) % 2;
    cgen->set_commands(
        [ 'cmp', $reg1, $reg2 ],
        [ 'j' . $ccs[$i], 'L1' ],
        [ 'mov', $reg3, $swap ? $reg2 : $reg1 ],
        [ 'jmp', 'L2' ],
        [ 'L1:' ],
        [ 'mov', $reg3, $swap ? $reg1 : $reg2 ],
        [ 'L2:' ],
    );
    my $code_txt = cgen->get_code_txt('%s');
    $self->{correct} = $signed * 2 + $min;
    $_ = "<code>$_</code>" for $reg1, $reg2, $reg3;
    $self->{text} =
        "По данным регистрам $reg1 и $reg2 " .
        "последовательность команд $code_txt вычислит в регистре $reg3:";
    $self->variants(cartesian_join(' ', ['знаковый', 'беззнаковый'], ['минимум', 'максимум']));
}

sub divisible_by_mask {
    my $self = shift;
    my ($reg) = cgen->get_reg(rnd->pick(16, 32));
    my ($n) = 2 ** rnd->in_range(2, 5);
    my $label = 'L';
    my $make_variant = sub {
        my ($cmd, $m, $cc) = @_;
        cgen->set_commands([ $cmd, $reg, $n + $m ], [ "j$cc", $label ]);
        cgen->get_code_txt('%s');
    };
    my @znz = qw(z nz);
    my $inv = rnd->coin;
    $self->variants(
        $make_variant->(rnd->pick(qw[test and]), -1, $znz[$inv]),
        $make_variant->(rnd->pick(qw[test and]), -1, $znz[1 - $inv]),
        $make_variant->(rnd->pick(qw[test and]), rnd->pick(0, +1, $n), rnd->pick(@znz)),
        $make_variant->('or', rnd->pick(-1, 0, +1), rnd->pick(@znz)),
        $make_variant->('or', $n, rnd->pick(@znz)),
    );
    $self->{text} = sprintf
        "Чтобы осуществить переход на метку <code>$label</code> в случае, " .
        "когда значение <code>$reg</code>%s кратно $n, нужно исполнить команды:",
        $inv ? ' не' : '';
}

1;
