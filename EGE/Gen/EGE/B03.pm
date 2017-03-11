# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B03;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use List::Util qw(min);

use EGE::Bits;
use EGE::Random;
use EGE::NotationBase qw(dec_to_base base_to_dec);
use EGE::NumText;

sub q1234 {
    my ($self) = @_;
    my $base = rnd->pick(5, 6, 7, 9, 11);
    $self->{text} =
        "Какое десятичное число в системе счисления по основанию $base " .
        "записывается как 1234<sub>$base</sub>?";
    $self->{correct} = base_to_dec($base, 1234);
    $self->accept_number;
}

sub last_digit {
    my ($self) = @_;
    my $base = rnd->in_range(5, 9);
    my $last = rnd->in_range(0, $base - 1);
    my @corr = map $last + $base * $_, 0 .. 3;
    my $limit = $corr[-1] + rnd->in_range(0, $base - 1);

    $self->{text} =
        'Укажите в порядке возрастания через запятую без пробелов ' .
        'все неотрицательные десятичные числа, ' .
        "<b><u>не превосходящие</u></b> $limit, запись которых в системе " .
        "счисления с основанием $base оканчивается на $last.";
    $self->{correct} = join ',', @corr;
    $self->{accept} = qr/^(?:\d+,)+(\d+)$/;
}

sub last_digit_base {
    my ($self) = @_;
    my ($number, $rem, @bases);
    do {
        $number = rnd->in_range(10, 60);
        $rem = rnd->in_range(1, 9);
        @bases = grep $number % $_ == $rem, 2 .. $number - 1;
    } while @bases < 2;
    $self->{text} =
        'Укажите в порядке возрастания через запятую без пробелов все основания систем счисления, ' .
        "в которых запись числа $number оканчивается на $rem.";
    $self->{correct} = join ',', @bases;
    $self->{accept} = qr/^(?:\d+,)+\d+$/;
}

sub count_digits {
    my ($self) = @_;
    my ($num, $base);
    do {
        $num = rnd->in_range(200, 900);
        $base = rnd->in_range(3, 9);
        $self->{correct} = length dec_to_base($base, $num);
    } until $self->{correct} > 3;
    $self->{text} =
        "Сколько значащих цифр в записи десятичного числа $num " .
        "в системе счисления с основанием $base?";
    $self->accept_number;
}

sub simple_equation {
    my ($self) = @_;
    my @dec_nums = map rnd->pick(20..200), 0..1;
    $dec_nums[2] = $dec_nums[0] + $dec_nums[1];
    my @bases = map rnd->pick(2..8), 0..2;
    my @nums = map dec_to_base($bases[$_], $dec_nums[$_]), 0..2;
    $self->{text} =
        "Решите уравнение $nums[0]<sub>$bases[0]</sub> + <i>x</i> = $nums[2]<sub>$bases[2]</sub> " .
        "Ответ запишите в системе счисления с основанием $bases[1]";
    $self->{correct} = $nums[1];
    $self->accept_number;
}

sub count_ones {
    my ($self) = @_;
    my $base = rnd->in_range(2, 10);

    my @large_power = map rnd->in_range(2013, 2025), 0..1;
    my @base_power = map rnd->in_range(1, 4), 0..2;
    my @summands_base = map $base ** $_, @base_power;
    my @answ = map $large_power[$_] * $base_power[$_], 0..1;
    my @nums_text = qw(единиц двоек троек четверок пятерок шестерок семерок восьмерок девяток);
    my @bases_text = qw(
        двоичной троичной четверичной пятиричной шестеричной семеричной восьмеричной девятиричной десятичной);

    $self->{text} =
        "Cколько $nums_text[$base - 2] в $bases_text[$base - 2] записи числа " .
        "$summands_base[0]<sup>$large_power[0]</sup> + " .
        "$summands_base[1]<sup>$large_power[1]</sup> - $summands_base[2]?";
    $self->{correct} = min(@answ) - $base_power[2] + ($base == 2 ? 1 : 0);
    $self->accept_number;
}

sub _music_data {
    my ($func_num) = @_;
    my %data = (
        more_less_ => rnd->coin,
        hig_low1_  => rnd->coin,
        hig_low2_  => rnd->coin,
        channels_n => rnd->coin,
        sec_min_   => rnd->coin,
        time       => rnd->in_range(1, 5),
        freq_      => rnd->in_range(2, 5),
        resol_     => rnd->in_range(2, 5),
        cap_       => rnd->in_range(2, 5),
        size       => rnd->pick(10, 12, 15, 21, 25, 28, 35, 50),
    );

    my @w1 = ('моно', 'стерео (двухканальная запись)');
    $data{channels_w_1} = $w1[$data{channels_n}];
    $data{channels_n} = $data{channels_n} == 1 ? 0 : 1;
    $data{channels_w_2} = $w1[$data{channels_n}];

    my $frac = 1;
    my $c = 0;
    $frac *= $data{resol_}, $c++ if $data{hig_low1_};
    $frac *= $data{freq_}, $c++ if $data{more_less_};
    $frac *= $data{cap_}, $c++ if !$data{hig_low2_};
    $frac *= 2, $c++ if !$data{channels_n} && $func_num;

    if (!$c) {
        $data{ans_time} = $data{resol_} * $data{freq_} * $data{cap_} * $data{time};
        $data{ans_time} *= 2 if $func_num;
    } elsif ($c == 4 || $c == 3 && !$func_num) {
        $data{ans_time} = rnd->in_range(2, 8);
        $data{time} = $frac * $data{ans_time};
    } else {
        $data{ans_time} = rnd->in_range(1, 8);
        $data{time} = $frac * $data{ans_time};
        $data{ans_time} *= $data{resol_} if !$data{hig_low1_};
        $data{ans_time} *= $data{freq_} if !$data{more_less_};
        $data{ans_time} *= $data{cap_} if $data{hig_low2_};
        $data{ans_time} *= 2 if $data{channels_n} && $func_num;
    }

    my @w2 = qw(больше меньше);
    $data{more_less} = $w2[$data{more_less_}];
    my @w3 = qw(выше ниже);
    $data{hig_low_1} = $w3[$data{hig_low1_}];
    $data{hig_low_2} = $w3[$data{hig_low2_}];

    $data{time_word_1} = $data{sec_min_} ?
        num_text($data{time}, [qw(секунду секунды секунд)]) : num_text($data{time}, [qw(минуту минуты минут)]);
    $data{question} = $data{sec_min_} ? 'секунд' : 'минут';

    $data{resol} = num_text($data{resol_}, [qw(раз раза раз)]);
    $data{freq}  = num_text($data{freq_}, [qw(раз раза раз)]);
    $data{cap}   = num_text($data{cap_}, [qw(раз раза раз)]);

    $frac = 1;
    $c = 0;
    $frac *= $data{resol_}, $c++ if $data{hig_low1_};
    $frac *= $data{freq_}, $c++ if $data{more_less_};
    $frac *= 2, $c++ if !$data{channels_n};

    if (!$c) {
        $data{ans_size} = $data{size} * $data{resol_} * $data{freq_} * 2;
    } elsif ($c == 3) {
        $data{ans_size} = rnd->in_range(2, 8);
        $data{size} = $frac * $data{ans_size};
    } else {
        $data{ans_size} = rnd->in_range(1, 8);
        $data{size} = $frac * $data{ans_size};
        $data{ans_size} *= $data{resol_} if !$data{hig_low1_};
        $data{ans_size} *= $data{freq_} if !$data{more_less_};
        $data{ans_size} *= 2 if $data{channels_n};
    }

    %data;
}

sub music_time_to_time {
    my ($self) = @_;
    my %data = _music_data(0);

    $self->{text} =
        'Музыкальный фрагмент был оцифрован и записан в виде файла без использования сжатия данных. ' .
        "Получившийся файл был передан в город А по каналу связи за $data{time_word_1}. " .
        "Затем тот же музыкальный фрагмент был оцифрован повторно с разрешением в $data{resol} $data{hig_low_1} " .
        "и частотой дискретизации в $data{freq} $data{more_less}, чем в первый раз. Сжатие данных не производилось. " .
        'Полученный файл был передан в город Б; пропускная способность канала связи с городом Б ' .
        "в $data{cap} $data{hig_low_2}, чем канала связи с городом А. Сколько $data{question} длилась передача ".
        'файла в город Б? В ответе запишите только целое число, единицу измерения писать не нужно.';

    $self->{correct} = $data{ans_time};
    $self->accept_number;
}

sub music_size_to_size {
    my ($self) = @_;
    my %data = _music_data(1);

    $self->{text} =
        "Музыкальный фрагмент был записан в формате $data{channels_w_1}, оцифрован и сохранён в виде файла ".
        "без использования сжатия данных. Размер полученного файла – $data{size} Мбайт. Затем тот ".
        "же музыкальный фрагмент был записан повторно в формате $data{channels_w_2} и ".
        "оцифрован с разрешением в $data{resol} $data{hig_low_1} и частотой дискретизации ".
        "в $data{freq} $data{more_less}, чем в первый раз. Сжатие данных не производилось. Укажите размер файла в Мбайт, ".
        'полученного при повторной записи. В ответе запишите только целое число, единицу измерения писать не нужно.';

    $self->{correct} = $data{ans_size};
    $self->accept_number;
}

sub music_format_time_to_time {
    my ($self) = @_;
    my %data = _music_data(2);

    $self->{text} =
        "Музыкальный фрагмент был записан в формате $data{channels_w_1}, оцифрован и сохранён в виде файла, ".
        'затем оцифрован и сохранён в виде файла без использования сжатия данных. Получившийся файл был '.
        "передан в город А по каналу связи за $data{time_word_1}. Затем тот же музыкальный фрагмент был ".
        "повторно записан в формате $data{channels_w_2} и оцифрован с разрешением в $data{resol} $data{hig_low_1} ".
        "и частотой дискретизации в $data{freq} $data{more_less}, чем в первый раз. Сжатие данных не производилось. ".
        'Полученный файл был передан в город Б; пропускная способность канала связи с городом Б в '.
        "$data{cap} $data{hig_low_2}, чем канала связи с городом А. Сколько $data{question} длилась передача файла в город Б? ".
        'В ответе запишите только целое число, единицу измерения писать не нужно.';

    $self->{correct} = $data{ans_time};
    $self->accept_number;
}

sub select_base {
    my ($self) = @_;
    my $base = rnd->in_range(3, 9);
    my $num = rnd->in_range(12, 500);
    my $converted_num = dec_to_base($base, $num);
    $self->{text} =
        'В си­сте­ме счис­ле­ния с не­ко­то­рым ос­но­ва­ни­ем де­ся­тич­ное число ' .
        "$num за­пи­сы­ва­ет­ся в виде $converted_num. Ука­жи­те это ос­но­ва­ние.";
    $self->{correct} = $base;
    $self->accept_number;
}

sub move_number {
    my ($self) = @_;
    my $base = rnd->in_range(3, 9);
    my $num = rnd->in_range(12, 500);
    my $converted_num = dec_to_base($base, $num);
    $self->{text} =
        "Запишите десятичное число $num в системе счисления с ос­но­ва­ни­ем $base. " .
        'Основание системы счисления (нижний индекс после числа) писать не нужно.';
    $self->{correct} = $converted_num;
    $self->accept_number;
}

1;
