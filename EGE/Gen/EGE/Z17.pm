# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::Z17;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub highest_result
{
    my ($self) = @_;
    my @products = ['факсы', 'пирнтеры', 'сканеры'];
    my $ans = 1;
    $self->{text} =" В таб­ли­це при­ве­де­ны за­про­сы к по­ис­ко­во­му сер­ве­ру. 
    Рас­по­ло­жи­те но­ме­ра за­про­сов в по­ряд­ке воз­рас­та­ния ко­ли­че­ства стра­ниц, ко­то­рые най­дет по­ис­ко­вый сер­вер по каж­до­му за­про­су.
    Для обо­зна­че­ния ло­ги­че­ской опе­ра­ции «ИЛИ» в за­про­се ис­поль­зу­ет­ся сим­вол |, а для ло­ги­че­ской опе­ра­ции «И» – &."; 
    $self->{correct} = $ans;
}
1;