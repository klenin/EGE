# Copyright © 2010-2013 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B08;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use POSIX qw(ceil);

use EGE::Random;
use EGE::NumText;
use EGE::Prog::Flowchart;
use EGE::LangTable;
use EGE::Bits;

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

sub _len_last {
    my ($num, $base) = @_;
    $num ? (ceil(log($num) / log($base)), $num % $base) : (0, 0);
}

sub _check_uniq {
    my ($num, $base) = @_;
    my ($len, $last) = _len_last($num, $base);
    for (my $base2 = 2; ; ++$base2) {
        next if $base2 == $base;
        my ($len2, $last2) = _len_last($num, $base2);
        return 0 if $len == $len2 && $last == $last2;
        last if $len2 < $len;
    }
    1;
}

sub find_calc_system {
    my ($self) = @_;
    my ($num, $base);
    do {
        ($num, $base) = (rnd->in_range(10, 99), rnd->in_range(2, 9));
    } while (!_check_uniq($num, $base));

    my ($len, $last) = _len_last($num, $base);
    my $len_text = num_text($len, [ 'цифру', 'цифры', 'цифр' ]);
    $self->{text} =
        "Запись числа $num<sub>10</sub> в системе счисления с " .
        "основанием <em>N</em> оканчивается на $last и содержит $len_text. " .
        'Чему равно основание этой системы счисления <em>N</em>?';
    $self->{correct} = $base;
    $self->accept_number;
}

sub two_bit {
    my ($number) = @_;
    my @n;
    for (my $i = 1; $i <= 9; $i++) {
        for (my $j = 0; $j <= 9; $j++) {
            if ($i + $j == $number){ 
                return @n = ($i, $j);
            }
        }
    }
}

sub three_bit {
    my ($number) = @_;
    my @n = ();
    for (my $i = 1; $i <= 9; $i++) {
        for (my $j = 0; $j <= 9; $j++) {
            for (my $k = 0; $k <= 9; $k++) {
                if ($i + $j + $k == $number){
                        return @n = ($i, $j, $k);
                    }
                }
            }
        }
    }

sub simple_amount {
    my ($self) = @_;
    my $a = rnd->pick(2, 3);
    my $b;
    my $x = 0;
    my $condition = rnd->pick('наибольшее', 'наименьшее');
    my @answer;

    ($a == 2) ? ($b = rnd->in_range(1, 18)) : ($b = rnd->in_range(1, 27));

    ($a == 2) ? (@answer = two_bit($b)) : (@answer = three_bit($b));

    if ($condition eq 'наибольшее') {
        if ($b < 10){
            ($a == 2) ? ($x = $b * 10) : ($x = $b * 100)        
        } else {
            @answer = reverse @answer;
            $x = join("", @answer);
        }
    } elsif (($b == 1) && ($a == 3)) {
        $x = 100
    } else {
        $x = join("", @answer)
    }

    my $block = EGE::Prog::make_block([
       '=', 'a', '0',
       '=', 'b', '0',
      'while', [ '>', 'x', '0' ], [
           '=', 'a', [ '+', 'a', '1' ],
            '=', 'b', ['()', 'b + ', ['%', 'x', '10'] ],
            '=', 'x', [ '//', 'x', '10' ],
        ],
    ]);
    my $lt = EGE::LangTable::table($block, [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C' ] ]);

    $self->{text} = 
        "Ниже на 4-х языках записан алгоритм. Получив на вход число x, этот алгоритм печатает" .
        "два числа a и b.  Укажите $condition из таких чисел x, при вводе которых алгоритм" .
        "печатает сначала $a, а потом $b." .
        "$lt <bi />",
    $self->{correct} = $x;
}

1;

=pod

=head1 Список генераторов

=over

=item identify_letter

=item find_calc_system

=back


=head2 Генератор find_calc_system

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание B08.

=head3 Автор генератора

Кевролетин В.В.

=head3 Описание

=over

=item *

Выбираются параметры - число(10 .. 100) и основание системы исчисления (2 .. 9)

=item *

Перебором проверяется, есть ли другие системы исчисления, в которых результат имеет столько же цифр
и такую же последнюю цифру. Если друга система счисления есть - параметры генерируются заново.

=back
