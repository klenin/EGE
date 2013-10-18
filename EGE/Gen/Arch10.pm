# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Gen::Arch10;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Asm::AsmCodeGenerate;

sub jcc_check_flags {
    my $self = shift;
    my $jmp = 'j' . rnd->pick('', 'n') . rnd->pick(qw(e g l ge le a b ae be));
    my $f = EGE::Asm::Eflags->new;
    my @flags = $f->flags;
    $self->variants(@flags);
    $self->{correct} = [ map $f->jump_checks_flag($jmp, $_), @flags ];
    $self->{text} = "Команда $jmp проверяет флаги:";
}

sub random_cc { rnd->pick('', 'n') . rnd->pick(qw(c p z o s e g l ge le a b ae be)) }

sub invert_cc { $_[0] =~ /^n(\w+)$/ ? $1 : "n$_[0]" }

sub cmovcc {
    my $self = shift;
    my ($reg1, $reg2) = cgen->get_regs(32, 32);
    my $cc = random_cc;
    my $label = 'L';
    cgen->clear;
    cgen->add_commands(
        [ "j$cc", $label ],
        [ 'mov', $reg1, $reg2 ],
        [ "$label:" ],
    );
    my $code_txt = cgen->get_code_txt('%s');
    $self->{text} = "Последовательность команд $code_txt эквивалентна команде:";

    my $cc_variants = sub { grep $_ eq $cc, @_ and [ map invert_cc($_), @_ ] };
    my $cc_variants_2 = sub { $cc_variants->(@_) || $cc_variants->(map invert_cc($_), @_) };

    my $variants =
        $cc_variants_2->(qw[c nae b]) || $cc_variants_2->(qw[z e]) || [ invert_cc($cc) ];
    $self->{correct} = [ (1) x @$variants, (0) x (4 - @$variants) ];
    push @$variants, $cc;
    while (@$variants < 4) {
        my $v = random_cc;
        push @$variants, $v if 0 == grep { $_ eq $v } @$variants;
    }
    $self->formated_variants("cmov%s $reg1, $reg2", @$variants);
}

1;
