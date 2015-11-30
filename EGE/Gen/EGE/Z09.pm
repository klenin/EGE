# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::Z09;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub get_memory_size
{
    my ($self) = @_;
    my $color_count = 2**rnd->in_range(6,10);
    my $picture_size = 2**rnd->in_range(6,10);
    my $ans = $picture_size**2 * log($color_count) / log(2) / 8 /1024;
    $self->{text} ="Какой минимальный объём памяти (в Кбайт) нужно зарезервировать, чтобы ".
        "можно было сохранить любое растровое изображение размером ".
        "$picture_size×$picture_size пикселов при условии, что в изображении могут использоваться ".
        "$color_count различных цветов? В ответе запишите только целое число, единицу ".
        "измерения писать не нужно."; 
    $self->{correct} = $ans;
}
1;