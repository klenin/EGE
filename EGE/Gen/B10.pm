# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B10;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub trans_arch {
    my ($self) = @_;
    my $K = 1024;
    my ($size, $compress_rate, $speed, $bef, $aft, $time1, $time2);
    do
    {
        $size = 10 * rnd->in_range(1, 5);
        $compress_rate = rnd->pick(10, 20, 50);
        $speed = rnd->in_range(23, 27);
        ($bef, $aft) = (rnd->in_range(5, 15), rnd->in_range(25, 35));
		
		my $Kspeed = 2**($speed - 18);
        $time1 = $size * $K / $Kspeed;
        $time2 =  $size * (100-$compress_rate) / 100 * $K / $Kspeed + $bef + $aft;
    } while($time1 == $time2 or $time2 - $time1 == 23);

    $self->{text} =
        "Документ объемом $size Мбайт можно передать с одного компьютера на другой двумя способами: <br/>\n" .
        "А) Сжать архиватором, передать архив по каналу связи, распаковать <br/>\n" . 
        "Б) Передать по каналу связи без использования архиватора. <br/>\n" .
        "Какой способ быстрее и насколько, если\n" .
        "<ul><li>средняя скорость передачи данных по каналу связи составляет 2<sup>$speed</sup> бит в секунду,</li>" .
        "<li>объем сжатого архиватором документа равен $compress_rate% от исходного,</li>" .
        "<li>время, требуемое на сжатие документа — $bef сек., на распаковку — $aft сек.?</li></ul>".
        "В ответе напишите букву А, если способ А быстрее или Б, если быстрее способ Б. " .
        "Сразу после буквы напишите количество секунд, насколько один способ быстрее другого. " .
        "Так, например, если способ Б быстрее способа А на 23 секунды, в ответе нужно написать Б23. " .
        "Слов «секунд», «сек.», «с.» к ответу добавлять <b>не нужно</b>.";

    $self->{correct} = $time1 > $time2? "А" . ($time1 - $time2): "Б" . ($time2 - $time1);
    $self->{accept} = qr/^[АБ]\d+/;
}

1;
