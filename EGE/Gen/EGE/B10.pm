# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B10;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::NumText;
use EGE::Random;
use EGE::Russian;

sub trans_rate {
    my ($self) = @_;
    my $K = 1024;
    my ($size, $compress_rate, $speed, $pack, $unpack, $time1, $time2);
    do {
        $size = 10 * rnd->in_range(1, 5);
        $compress_rate = rnd->pick(10, 20, 50);
        $speed = rnd->in_range(23, 27);
        $pack = rnd->in_range(5, 15);
        $unpack = rnd->in_range(25, 35);

        my $Kspeed = 2**($speed - 18);
        $time1 = $size * $K / $Kspeed;
        $time2 = $size * (100 - $compress_rate) / 100 * $K / $Kspeed + $pack + $unpack;
    # Отсекаем неоднозначный ответ (А0, Б0) и ответ Б23 из примера.
    } while ($time1 == $time2 || $time2 - $time1 == 23);

    $self->{text} =
        "Документ объемом $size Мбайт можно передать с одного компьютера на другой двумя способами: <br/>\n" .
        "А) Сжать архиватором, передать архив по каналу связи, распаковать <br/>\n" .
        "Б) Передать по каналу связи без использования архиватора. <br/>\n" .
        "Какой способ быстрее и насколько, если\n" .
        "<ul><li>средняя скорость передачи данных по каналу связи составляет 2<sup>$speed</sup> бит в секунду,</li>" .
        "<li>объем сжатого архиватором документа равен $compress_rate% от исходного,</li>" .
        "<li>время, требуемое на сжатие документа — $pack сек., на распаковку — $unpack сек.?</li></ul>".
        "В ответе напишите букву А, если способ А быстрее или Б, если быстрее способ Б. " .
        "Сразу после буквы напишите количество секунд, насколько один способ быстрее другого. " .
        "Так, например, если способ Б быстрее способа А на 23 секунды, в ответе нужно написать Б23. " .
        "Слов «секунд», «сек.», «с.» к ответу добавлять <b>не нужно</b>.";

    $self->{correct} = ($time1 > $time2 ? 'А' : 'Б') . abs($time2 - $time1);
    $self->{accept} = qr/^[АБ]\d+$/;
}

sub _trans_init_common {
    my ($self) = @_;
    my $size = rnd->in_range(10, 50);
    my $speed1 = rnd->in_range(18, 23);
    my $speed2 = rnd->in_range_except(18, 23, $speed1);
    $self->{time_sec} = (2 ** (23 - $speed1) + 2 ** (23 - $speed2)) * $size;
    $self->{text} =
        "Данные объемом $size Мбайт передаются из пункта А в пункт Б по каналу связи, обеспечивающему скорость " .
        "передачи данных 2<sup>$speed1</sup> бит в секунду, а затем из пункта Б в пункт В по каналу связи, " .
        "обеспечивающему скорость передачи данных 2<sup>$speed2</sup> бит в секунду. ";
    $self->accept_number;
}

sub trans_time {
    my ($self) = @_;

    $self->_trans_init_common;
    my $latency = rnd->in_range(13, 35);

    $self->{text} .= sprintf
        'Задержка в пункте Б (время между окончанием приема данных из пункта А ' .
        'и началом передачи в пункт В) составляет %s. ' .
        'Сколько времени (в секундах) прошло с момента начала передачи данных из пункта А ' .
        'до их полного получения в пункте В? ' .
        'В ответе укажите только число, слово «секунд» или букву «с» добавлять <b>не нужно</b>.',
        num_text($latency, [ qw(секунду секунды секунд) ]) ;
    $self->{correct} = $self->{time_sec} + $latency;
}

sub trans_latency {
    my ($self) = @_;

    $self->_trans_init_common;
    my $minutes = int($self->{time_sec} / 60) + rnd->in_range(1, 3);
    my $latency = $minutes * 60 - $self->{time_sec};

    $self->{text} = sprintf
        'От начала передачи данных из пункта А до их полного ' .
        'получения в пункте В прошло %s. ' .
        'Сколько времени в секундах составила задержка в пункте Б, ' .
        'т.е. время между окончанием приема данных из пункта А и началом передачи данных в пункт В? ' .
        'В ответе укажите только число, слово «секунд» или букву «с» добавлять <b>не нужно</b>.',
        num_text($minutes, [ qw(минута минуты минут) ]) ;
    $self->{correct} = $latency;
}

sub min_period_of_time {
    my ($self) = @_;

    my $high_speed = rnd->in_range(17, 23);
    my $slow_speed = rnd->in_range(12, 15);
    my $required_data = rnd->in_range(6, 12);
    my $full_data = 2 ** rnd->in_range($high_speed - 13, 10);

    my $male_or_female  = rnd->coin;
    my $female_name = rnd->pick(@EGE::Russian::Names::female);
    my $male_name = rnd->pick(@EGE::Russian::Names::male);
    my $name_first = $male_or_female ? $female_name : $male_name;
    my $name_second = $male_or_female ? $male_name : $female_name;
    my $argeed = $male_or_female ? 'договорился' : 'договорилась';
    my $she_he = $male_or_female ? 'она' : 'он';

    my $genitive_first  = EGE::Russian::Names::genitive($name_first);
    my $ablative_first  = EGE::Russian::Names::ablative($name_first);
    my $genitive_second = EGE::Russian::Names::genitive($name_second);
    my $ablative_second = EGE::Russian::Names::ablative($name_second);
    my $dative_second   = EGE::Russian::Names::dative($name_second);

    $self->{text} =
        "<p>У $genitive_first есть доступ к сети Интернет по высокоскоростному одностороннему радиоканалу, " .
        "обеспечивающему скорость получения информации 2<sup>$high_speed</sup> бит в секунду. " .
        "У $genitive_second нет скоростного доступа в Интернет, но есть возможность получать информацию " .
        "от $genitive_first по телефонному каналу со средней скоростью 2<sup>$slow_speed</sup> бит в секунду. " .
        "$name_second $argeed с $ablative_first, что $she_he скачает для него данные объемом $required_data " .
        "Мбайт по высокоскоростному каналу и ретранслирует их $dative_second по низкоскоростному каналу.</p> " .

        "<p>Компьютер $genitive_first может начать ретрансляцию данных не раньше, чем им будут получены " .
        "первые $full_data Кбайт этих данных. Каков минимально возможный промежуток времени " .
        "(в секундах) с момента начала скачивания $ablative_first данных до полного их получения " .
        "$ablative_second?</p> " .

        '<p>В ответе укажите только число, слово «секунд» или букву «с» добавлять не нужно.</p>';

    $self->{correct} = 2 ** (23 - $slow_speed) * $required_data  + $full_data * 2 ** (13 - $high_speed);
    $self->accept_number;
}

sub trans_text {
    my ($self) = @_;
    my $speed = (2 ** rnd->in_range(3, 9)) * (10 ** rnd->in_range(2, 3));
    my $seconds = rnd->in_range(10, 40);
    my $typecon = $speed < 52000 ? 'модемное ' : 'ADSL-';
    $self->{text} = sprintf
        'Скорость передачи данных через %sсоединение равна %d бит/с. ' .
        'Передача текстового файла через это соединение заняла %s. ' .
        'Определите, сколько символов содержал переданный текст, если известно, ' .
        'что он был представлен в 16-битной кодировке Unicode.',
        $typecon, $speed, num_text($seconds, [ qw(секунду секунды секунд) ]);
    $self->{correct} = $speed * $seconds / 16;
    $self->accept_number;
}

sub trans_time_size {
    my ($self) = @_;
    my $Kspeed = 2 ** rnd->in_range(9, 10);
    my $time1 = rnd->in_range(1, 7) * 2;
    my $time2 = rnd->in_range(1, 7) * 2;
    my $time = $time1 + $time2;
    $self->{text} =
        "По каналу связи непрерывно в течение $time часов передаются данные. " .
        "Скорость передачи данных в течение первых $time1 " .
        "часов составляет $Kspeed Кбит в секунду, а в остальное время — в два раза меньше. " .
        'Сколько Мбайт данных было передано за время работы канала?';
    $self->{correct} = ($time1 + $time2 / 2)  * 3600 * $Kspeed / 8192;
    $self->accept_number;
}

1;
