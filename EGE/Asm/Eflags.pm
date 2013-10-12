# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/NZem/EGE
package EGE::Asm::Eflags;

use strict;
use warnings;

my $flags = [ qw(ZF SF PF CF OF) ];

my $jump_conds;

sub prepare_jumps {
    my %jumps = qw(
        jc:jb:jnae  CF
        jp          PF
        jz:je       ZF
        js          SF
        jo          OF
        jnc:jae:jnb !CF
        jnp         !PF
        jnz:jne     !ZF
        jns         !SF
        jno         !OF
        jl:jnge     SF!=OF
        jle:jng     SF!=OF||ZF
        jg:jnle     SF==OF&&!ZF
        jge:jnl     SF==OF
        jbe:jna     CF||ZF
        ja:jnbe     !CF&&!ZF
        jmp         1
    );
    while (my ($jumps, $flags) = each %jumps) {
        (my $cond = $flags) =~ s/(\wF)/\$_[0]->{$1}/g;
        my $code = eval "sub { $cond }";
        $jump_conds->{$_} = $code for split ':', $jumps;
    }
    $jump_conds;
}

sub flags_text { join ' ', sort grep $_[0]->{$_}, @$flags }

sub new {
    my ($class, %init) = @_;
    my $self = {};
    $jump_conds or prepare_jumps;
    bless $self, ref $class || $class;
    $self;
}

sub init {
    my $self = shift;
    $self->{$_} = 0 for @$flags;
}

sub valid_jump {
    my ($self, $cmd) = @_;
    $jump_conds->{$cmd}->($self);
}

1;
