# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch::Arch01;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::Processor;
use EGE::Asm::AsmCodeGenerate;

sub offs_modulo {
    my ($val, $modulo, @offs) = @_;
    map { ($val + $_ + $modulo) % $modulo } @offs;
}

sub run_modified {
    my ($idx, $modify, $get) = @_;
    $_ = local cgen->{code}->[$idx] = cgen->{code}->[$idx];
    $modify->();
    proc->run_code(cgen->{code})->get_val($get);
}

sub toggle { $_[0] eq $_[1] ? $_[2] : $_[1]; }

sub make_wrongs {
    my ($reg, $upto, @variants) = @_;
    my @wrongs;
    for (my $i = 0; @variants + @wrongs < $upto && $i < 100; ++$i) {
        my $res = proc->get_wrong_val($reg);
        push @wrongs, $res unless grep { $res eq $_ } @variants, @wrongs;
    }
    @wrongs;
}

sub reg_value_add {
    my $self = shift;
    my ($reg, $format, $n) = cgen->generate_simple_code('add');
    my @variants = $self->get_res($reg, $format);
    push @variants, offs_modulo($variants[0], 2 ** $n, rnd->pick(2, -2), 1, - 1)
        if $n == 8 || cgen->cmd(1) =~ /^(stc|clc)$/;
    $self->formated_variants($format, @variants, make_wrongs($reg, 4, @variants));
}

sub reg_value_bscan {
    my $self = shift;
    my ($reg1, $reg2, $format_variants, $format_code) = cgen->generate_bscan_code;
    my @variants = $self->get_res($reg1, $format_code);
    push @variants, offs_modulo($variants[0], 2 ** 16, rnd->pick(2, -2), 1, - 1);
    $self->formated_variants($format_variants, @variants);
}

sub reg_value_logic {
    my $self = shift;
    my ($reg, $format, $n) = cgen->generate_simple_code('logic');
    my @variants = $self->get_res($reg, $format);
    if (cgen->cmd(1) eq 'test') {
        my $w = run_modified 1, sub { $_->[0] = 'and' }, $reg;
        push @variants, $w if $variants[0] ne $w;
    }
    $self->formated_variants($format, @variants, make_wrongs($reg, 4, @variants));
}

sub try_reg_value_shift {
    my $self = shift;
    my ($reg, $format, $n, $arg) = cgen->generate_simple_code('shift');
    my $use_cf = cgen->cmd(1) =~ /^(stc|clc)$/;
    my $shift_idx = $use_cf ? 2 : 1;

    my $make_wa = sub { run_modified($shift_idx, $_[0], $reg) };
    my $shift_right = $arg >= 2 ** ($n - 1) && (cgen->cmd($shift_idx) =~ /^(shr|sar)$/);

    my @variants = (
        $self->get_res($reg, $format),
        ($use_cf ? $make_wa->(sub { $_->[0] =~ s/^rc/ro/ }) : ()),
        ($shift_right ? $make_wa->(sub { $_->[0] = toggle($_->[0], 'shr', 'sar') }) : ()),
        $make_wa->(sub { $_->[2] += $_->[2] == $n / 8 ? $n / 8 : rnd->pick($n / 8, -$n / 8) }),
        $make_wa->(sub { $_->[0] =~ s/^(\w\w)(l|r)$/$1 . toggle($2, 'r', 'l')/e })
    );
    my %h;
    @h{@variants} = undef;
    keys %h == @variants or return 0;
    $self->formated_variants($format, @variants, make_wrongs($reg, 4, @variants));
    1;
}

sub reg_value_shift {
    1 until $_[0]->try_reg_value_shift;
}

sub reg_value_convert {
    my $self = shift;
    my ($reg32, $reg16) = cgen->get_regs(32, 16);
    my ($cmd, $bad_cmd) = rnd->shuffle(qw(movzx movsx));
    cgen->set_commands(
        [ 'mov', $reg16, 15 * 2**12 + rnd->in_range(0, 2**12 - 1) ],
        [ $cmd, $reg32, $reg16 ]);
    my @variants = (
        $self->get_res($reg32, '%04Xh'),
        run_modified 1, sub { $_->[0] = $bad_cmd }, $reg32);
    my $resz = $variants[$cmd eq 'movzx' ? 0 : 1];
    $self->formated_variants('%08Xh', @variants, 15 * 2**28 + $resz, 2**31 + $resz);
}

sub reg_value_jump {
    my $self = shift;
    my $reg = cgen->get_reg(8);
    my $label = 'L';
    my $jmp = 'j' . rnd->pick('n', '') . rnd->pick(qw(c p z o s e g l ge le a b ae be));
    cgen->set_commands(
        cgen->random_mov($reg),
        cgen->random_command('add', $reg),
        [ $jmp, $label ],
        [ 'add', $reg, 1 ],
        [ "$label:" ],
    );
    my $res = $self->get_res($reg, '%s');
    $self->variants($res, offs_modulo($res, 256, rnd->pick(2, -2), 1, -1));
}

sub reg_value_div {
    my $self = shift;
    my ($reg, $format, $n) = cgen->generate_div_code('div');
    my @variants = $self->get_res($reg, $format);
    push @variants, offs_modulo($variants[0], 2 ** $n, rnd->pick(2, -2), 1, - 1);
    $self->formated_variants($format, @variants, make_wrongs($reg, 4, @variants));
}

sub get_res {
    my ($self, $reg, $format) = @_;
    my $code_txt = cgen->get_code_txt($format);
    $self->{text} = "В результате выполнения кода $code_txt в регистре $reg будет содержаться значение:";
    proc->run_code(cgen->{code})->get_val($reg);
}

1;
