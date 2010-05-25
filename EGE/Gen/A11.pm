# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A11;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bits;

sub variable_length {
    my ($self) = @_;
    my %code = ( 'А' => '00', 'Б' => '11', 'В' => '010', 'Г' => '011' );
    my @letters = sort keys %code;
    my $symt = join(', ', @letters[0 .. $#letters - 1]) . ' и ' . $letters[-1];
    my $codet = join ', ', map "$_ - $code{$_}", @letters;

    my @msg = map rnd->pick(@letters), 1..6;
    my $msgt = join '', @msg;

    my $bs = EGE::Bits->new->set_bin(join '', map $code{$_}, @msg);
    my $bad_bs = EGE::Bits->new->set_bin(
        join '', map substr('000' . $code{$_}, -3), @msg
    );

    my $c = 'A';
    my %bad_letters = map { $_ => $c++ } @letters;
    my $bads = join '', map $bad_letters{$_}, @msg;

    $self->{text} =
        'Для передачи по каналу связи сообщения, состоящего только из ' .
        "символов $symt, используется неравномерный (по длине) код: $codet. " .
        "Через канал связи передаётся сообщение: $msgt. " .
        'Закодируйте соощение данным кодом. ' .
        'Полученную двоичную последовательность переведите в восьмеричный вид.';
    $self->variants($bs->get_oct, $bs->get_hex, $bad_bs->get_oct, $bads);
}

sub fixed_hex { EGE::Bits->new->set_bin(join '', @_)->get_hex }

sub fixed_length {
    my ($self) = @_;
    my %code = ( 'А' => '00', 'Б' => '01', 'В' => '10', 'Г' => '11' );
    my @letters = sort keys %code;
    my $symt = join ', ', @letters;

    my @msg = map rnd->pick(@letters), 1..4;
    my $msgt = join '', @msg;

    my $good = fixed_hex map $code{$_}, @msg;
    my @bad = (
        fixed_hex(map "00$code{$_}", @msg),
        fixed_hex(map "$code{$_}00", @msg));
    do {
        $bad[2] = fixed_hex map $code{$_}, rnd->shuffle(@msg);
    } while $bad[2] eq $good;

    $self->{text} =
        "Для кодирования букв $symt решили использовать двухразрядные " .
        'последовательные двоичные числа (от 00 до 11, соответственно). ' .
        "Если таким способом закодировать последовательность символов $msgt и " .
        'записать результат в шестнадцатеричной системе счисления, то получится',
    $self->variants($good, @bad);
}

1;
