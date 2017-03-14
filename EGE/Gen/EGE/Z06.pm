# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::Z06;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bits;
 use List::Util qw(min);

use List::Util qw(min max);

sub find_number {
    my ($self) = @_;
    my $minimal_number = rnd->in_range(8,4096);
    my $N = EGE::Bits->new;
    $N->set_size(int(log($minimal_number + 1) / log(2)) + 1);
    $N->set_dec($minimal_number + 1);

    $N->inc_autosize if $N->get_bit(0) == 1;
    while (1) {
        my $size = $N->get_size;
        my $unit_count = 0;  
        for my $i (2..($size - 1)) { $unit_count++ if $N->get_bit($i) }
        last if $N->get_bit(1) == $unit_count % 2;
        for my $i (1..2) { $N->inc_autosize }
    }
    $N->shift_(2);
    $self->{text} = 
        "На вход ал­го­рит­ма подаётся на­ту­раль­ное число N. Ал­го­ритм стро­ит по нему новое число R сле­ду­ю­щим об­ра­зом: <br />".
        "1. Стро­ит­ся дво­ич­ная за­пись числа N.<br />".
        "2. К этой за­пи­си до­пи­сы­ва­ют­ся спра­ва ещё два раз­ря­да по сле­ду­ю­ще­му пра­ви­лу: <br />".
        "а) скла­ды­ва­ют­ся все цифры дво­ич­ной за­пи­си, и оста­ток от де­ле­ния суммы на 2 до­пи­сы­ва­ет­ся в конец числа (спра­ва).<br />".
        "На­при­мер, за­пись 11100 пре­об­ра­зу­ет­ся в за­пись 111001; <br />".
        "б) над этой за­пи­сью про­из­во­дят­ся те же дей­ствия – спра­ва до­пи­сы­ва­ет­ся оста­ток от де­ле­ния суммы цифр на 2. <br />".
        "По­лу­чен­ная таким об­ра­зом за­пись (в ней на два раз­ря­да боль­ше, чем в за­пи­си ис­ход­но­го числа N) яв­ля­ет­ся дво­ич­ной за­пи­сью ис­ко­мо­го числа R.<br />".
        "Ука­жи­те такое наи­мень­шее число N, для ко­то­ро­го ре­зуль­тат ра­бо­ты ал­го­рит­ма боль­ше $minimal_number. В от­ве­те это число за­пи­ши­те в де­ся­тич­ной си­сте­ме счис­ле­ния.";
    $self->{correct} = $N->get_dec;
}

sub _get_min_origin {
    my @r = split '', $_[0];
    join '',
        @r == 2 ? (1, $r[0] - 1, $r[1] - $r[0] + 1) :
        # 920 -> 211
        @r == 3 ? ("$r[1]$r[2]" - $r[0] == 9 ? (9, $r[0], 0) : (1, $r[0] - 1, "$r[1]$r[2]" - $r[0] + 1)) :
        @r == 4 ? ("$r[0]$r[1]" - 9, 9, "$r[2]$r[3]"  - 9) : die;
}

sub _convert {
    my ($x, $y, $z) = split '', $_[0];
    join '', sort { $a <=> $b } $x + $y, $y + $z;
}

sub min_add_digits {
    my ($self) = @_;
    my ($orig, $result);
    do {
        # Не генерировать числа кратные 100.
        $orig = rnd->in_range(1, 9) * 100 + rnd->in_range(1, 99);
        $result = _convert($orig);
    } while $result == 712; # Не генерировать число из примера.

    $self->{text} = <<QUESTION
Автомат получает на вход трёхзначное число. По этому числу строится новое число по следующим правилам.
<ol>
<li>Складываются первая и вторая, а также вторая и третья цифры исходного числа.</li>
<li>Полученные два числа записываются друг за другом в порядке возрастания (без разделителей).</li>
</ol>
Пример. Исходное число: 348. Суммы: 3+4 = 7; 4+8 = 12. Результат: 712.<br />
Укажите наименьшее число, в результате обработки которого автомат выдаст число $result.
QUESTION
;
    $self->{correct} = _get_min_origin($result);
    $result == _convert($self->{correct}) or die "$orig => $result, min = $self->{correct}";
    $self->{correct} <= $orig or die "$orig => $result, min = $self->{correct}";
}

sub grasshopper {
    my ($self) = @_;
    my $forward = rnd->in_range(2, 15);
    my $backward = rnd->in_range_except(2, 9, $forward);
    my $back_cnt = rnd->in_range(2, 15);
    my $length = ($backward * $back_cnt) % $forward;
    my $start_pnt = rnd->in_range(0, 20);
    my $end_pnt = $start_pnt + $length;
    my $min = $back_cnt;
    for (0 .. ($back_cnt - 1)) {
        if (($length + $backward * $_) % $forward == 0) {
            $min = min($min, $_);
            last;
        }
    }
    $self->{text} = 
        "Исполнитель КУЗНЕЧИК живёт на числовой оси. Начальное положение КУЗНЕЧИКА – точка $start_pnt. Система команд Кузнечика:<br />
         Вперед $forward – Кузнечик прыгает вперёд на $forward единиц,<br />
         Назад $backward – Кузнечик прыгает назад на $backward единиц.<br />
         Какое наименьшее количество раз должна встретиться в программе команда «Назад $backward», чтобы Кузнечик оказался в точке $end_pnt?";
    $self->{correct} = $min;
    $self->accept_number;
}

1;
