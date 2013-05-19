# Copyright © 2010-2013 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A11;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bits;
use EGE::NumText;

use EGE::Gen::A02;

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

sub _password_length_text {
    my ($c) = @_;
}

sub password_length {
    my ($self) = @_;

    my $context = {
        case_sensitive => 1,
        sym_cnt => rnd->in_range(1, 20),
        items_cnt => rnd->in_range(1, 10) * 10,
    };
    EGE::Gen::A02::_car_num_make_alphabet($context);
    EGE::Gen::A02::_car_num_gen_task($context);
    my $fmt = <<QUESTION
Для регистрации на сайте некоторой страны пользователю требуется придумать пароль.
Длина пароля – ровно %s. В качестве символов используются %s.
Под хранение каждого такого пароля на компьютере отводится минимально возможное и
одинаковое целое количество байтов, при этом используется посимвольное кодирование
и все символы кодируются одинаковым и минимально возможным количеством битов.
Определите объём памяти, который занимает хранение %s.
QUESTION
;
    $self->{text} = sprintf $fmt,
        num_text($context->{sym_cnt}, [ 'символ', 'символа', 'символов' ]),
        $context->{alph_text},
        num_text($context->{items_cnt}, [ 'пароля', ('паролей') x 2 ]);
    $self->{variants} = $context->{result};
}

1;


__END__

=pod

=head1 Список генераторов

=over

=item variable_length

=item fixed_length

=item password_length

=back


=head2 Генератор password_length

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание A11.

=head3 Описание

Модифицированное задание A02 car_numbers. Вводится дополнительная сложность -
буквы алфавита используются в 2х начертаниях: строчные и прописные, что добавляет
одну арифмитическую операция при вычисления.
