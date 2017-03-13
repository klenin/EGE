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

sub get_origin {
    my ($a, $b) = @_;
    my $min_res = 1000;
    for my $x (0 .. min(9, $a)) {
        for my $z (0 .. min(9, $b)) {
            if ($x == $z && $x == 0) {
                next;
            }
            my $y = $a - $x;
            if (($a - $x == $b - $z) && ($y < 10)) {
                if (($x > $z && $z != 0) || ($x == 0)) {
                    ($x, $z) = ($z, $x);
                }
                $min_res = min($min_res, $x . $y . $z);
            }
        }
    }
    return $min_res;
}

sub convert_number {
    my ($self) = @_;
    my $f_num = rnd->in_range(1, 18);
    my $s_num = rnd->in_range(max($f_num - 9, 1), $f_num);

    $self->{text} = <<QUESTION
Автомат получает на вход трёхзначное число. По этому числу строится новое число по следующим правилам.<br />
1. Складываются первая и вторая, а также вторая и третья цифры исходного числа.<br />
2. Полученные два числа записываются друг за другом в порядке возрастания (без разделителей).<br />

Пример. Исходное число: 348. Суммы: 3+4 = 7; 4+8 = 12. Результат: 712.<br />
Укажите наименьшее число, в результате обработки которого автомат выдаст число $f_num$s_num.
QUESTION
;
    $self->{correct} = get_origin($s_num, $f_num);
}

1;
