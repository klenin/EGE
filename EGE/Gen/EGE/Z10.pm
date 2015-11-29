# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::Z10;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub words_count
{
    my ($self) = @_;
    my $n = rnd->in_range(3,10);
    my $first_symb;
    my $ans = 3**$n;
    if (rnd->coin){
        $first_symb = 'гласной';
        $ans -=3**($n-1);
    } else{
        $first_symb = 'согласной';
        $ans -= 2*3**($n-1);
    }
    $self->{text} ="Сколь­ко слов длины $n, на­чи­на­ю­щих­ся с глас­ной буквы, можно со­ста­вить из букв Е, Г, Э?
    Каж­дая буква может вхо­дить в слово не­сколь­ко раз. 
    Слова не обя­за­тель­но долж­ны быть осмыс­лен­ны­ми сло­ва­ми рус­ско­го языка."; 
    $self->{correct} = $ans;
}
1;