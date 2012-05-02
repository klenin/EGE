# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B08;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NumText;

sub identify_letter {
    my ($self) = @_;
    my $n = rnd->in_range(6, 10);
    my $dn = rnd->in_range(1, $n - 1);
    my $dx = rnd->in_range(1, $n - $dn);

    $self->{text} .= <<QUESTION
Строки (цепочки символов латинских букв) создаются по следующему
правилу.
Первая строка состоит из одного символа — латинской буквы «A». Каждая из
последующих цепочек создается такими действиями: в очередную строку
сначала записывается буква, чей порядковый номер в алфавите
соответствует номеру строки (на <em>i</em>-м шаге пишется <em>i</em>-я буква алфавита), к ней
слева дважды подряд приписывается предыдущая строка.
Вот первые 4 строки, созданные по этому правилу:
<ol>
<li>A</li>
<li>AAB</li>
<li>AABAABC</li>
<li>AABAABCAABAABCD</li>
</ol>
<p><i><b>Латинский алфавит (для справки)</b></i>:
ABCDEFGHIJKLMNOPQRSTUVWXYZ</p>
Имеется задание:
«Определить символ, стоящий в <em>n</em>-й строке на позиции
<strong>2<sup><em>n</em>−$dn</sup> − $dx</strong>, считая от
левого края цепочки».
<br/>Выполните это задание для <strong><em>n</em> = $n</strong>
QUESTION
;
    $self->{correct} = ['A' .. 'Z']->[$n - $dn - $dx];
}

sub _dec_to_n {
    my ($num, $n) = @_;
    my $res = '';
    do {
        $res = ($num % $n) . $res;
        $num = int($num / $n);
    } while ($num);
    $res
}

sub _len_last {
    my ($num, $base) = @_;
    $_ = _dec_to_n($num, $base);
    (length($_), substr($_, length($_) - 1, 1))
}

sub _check_uniq {
    my ($num, $base) = @_;
    my ($len, $last) = _len_last($num, $base);
    for my $n (2 .. 9) {
        if ($n != $base) {
            my ($len2, $last2) = _len_last($num, $n);
            return 0 if $len == $len2 && $last == $last2
        }
    }
    1
}

sub find_calc_system {
    my ($self) = @_;
    my ($num, $base);
    do {
        ($num, $base) = (rnd->in_range(10, 99), rnd->in_range(2, 9));
    } while (!_check_uniq($num, $base));

    my ($len, $last) = _len_last($num, $base);
    my $len_text = num_text($len, ['цифру', 'цифры', 'цифр']);
    $self->{text} = "Запись числа $num<sub>10</sub> в системе счисления с " .
        "основанием N оканчивается на $last и содержит $len_text. Чему равно " .
        "основание этой системы счисления N?";
    $self->{correct} = $base;
    $self->accept_number();
}

1;

=pod

=head1 Список генераторов

=over

=item identify_letter

=item find_calc_system

=back


=head2 Генератор min_routes

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание B08.

=head3 Автор генератора

Кевролетин В.В.

=head3 Описание

=over

=item *

Вибираются параметры - чило(10 .. 100) и основание системы исчисления (2 .. 9)

=item *

Перебором проверяется, есть ли другие системы исчисления, в которых результат имеет столько же цифр
и такую же последнюю цифру. Если друга система счисления есть - параметры генерируются заново.

=back
