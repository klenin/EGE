# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B10;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

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

sub _trans_text{
    my ($size, $speed1, $speed2) = @_;
    my $text =
        "Данные объемом $size Мбайт передаются из пункта А в пункт Б по каналу связи, обеспечивающему скорость" .
        "передачи данных <i><b>2<sup>$speed1</sup></b></i> бит в секунду, а затем из пункта Б в пункт В по каналу связи," . 
        "обеспечивающему скорость передачи данных <i><b>2<sup>$speed2</sup></b></i> бит в секунду.";
}

sub _trans_data{
    my %data = (
        size => 10 * rnd->in_range(5, 50),
        speed1 => rnd->in_range(18, 23),
        speed2 => rnd->in_range(18, 23),
        latency => rnd->in_range(13, 35),
    );
    $data{time} =
        2**(23 - $data{speed1}) * $data{size} + 
        2**(23 - $data{speed2}) * $data{size} + $data{latency};
    %data;
}

sub trans_time {
    my ($self) = @_;
    my %data = _trans_data;

    $self->{text} = 
        _trans_text($data{size}, $data{speed1}, $data{speed2}) .
        "Задержка в пункте Б " .
        "(время между окончанием приема данных из пункта А и началом передачи в пункт В) составляет $data{'latency'} секунды. " . 
        "Сколько времени (в секундах) прошло с момента начала передачи данных из пункта А до их полного получения в " .
        "пункте В? В ответе укажите только число, слово «секунд» или букву «с» добавлять <b>не нужно</b>.";
    $self->{correct} = $data{'time'};
}

sub trans_latency{
    my ($self) = @_;
    my %data = _trans_data;
    
    $self->{text} = 
        _trans_text($data{size}, $data{speed1}, $data{speed2}) .
        "От начала передачи данных из пункта А до их полного " .
        "получения в пункте В прошло $data{'time'} минут. Сколько времени в секундах составила задержка в пункте Б, " .
        "т.е. время между окончанием приема данных из пункта А и началом передачи данных в пункт В? " .
        "В ответе укажите только число, слово «секунд» или букву «с» добавлять <b>не нужно</b>.";
    $self->{correct} = $data{latency};
}

1;
