# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::Z10;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub words_count {
    my ($self) = @_;

    my $n = rnd->in_range(4, 6);
    my @consonants = rnd->pick_n(rnd->in_range(1,3), split //, 'БВГДЖЗКЛМНПРСТФХ');
    my @vowels = rnd->pick_n($n - @consonants, split //, 'АЕИОУЫЭЮЯ');

    my $r = rnd->coin ?
      { first => 'гласной', num => @vowels * $n ** ($n-1) } :
      { first => 'согласной', num => @consonants * $n ** ($n-1) };

    $self->{text} =
        "Сколь­ко слов длины $n, на­чи­на­ю­щих­ся с $r->{first} буквы, можно со­ста­вить из букв: " .
        join(', ', rnd->shuffle(@consonants, @vowels)) .
        '. Каж­дая буква может вхо­дить в слово не­сколь­ко раз. ' .
        'Слова не обя­за­тель­но долж­ны быть осмыс­лен­ны­ми сло­ва­ми рус­ско­го языка.';
    $self->{correct} = $r->{num};
}

1;
