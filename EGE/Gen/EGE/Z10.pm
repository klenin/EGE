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
    my $n = rnd->in_range(3,6);
    my $first_symb;
    my $consonants = '';
    my $vowels = '';
    for my $i (1..rnd->in_range(1,3)){ $consonants = $consonants . rnd->russian_consonant_letter}; 
    for my $i (1..rnd->in_range(1,3)){ $vowels = $vowels . rnd->russian_vowel_letter };
    
    foreach(($vowels,$consonants)) { $_=~ s/(.) (?: \1*)/$1/gx};
    my @all_letters =split(//, $consonants . $vowels);
    my $ans = @all_letters**$n;
    
    if (rnd->coin){
        $first_symb = 'гласной';
        $ans -= (length $consonants) * @all_letters**($n-1);
    } else{
        $first_symb = 'согласной';
        $ans -= (length $vowels) * @all_letters**($n-1);
    }
    $self->{text} ="Сколь­ко слов длины $n, на­чи­на­ю­щих­ся с $first_symb буквы, можно со­ста­вить из букв: ". join(", ", @all_letters) .
        ". Каж­дая буква может вхо­дить в слово не­сколь­ко раз.". 
        "Слова не обя­за­тель­но долж­ны быть осмыс­лен­ны­ми сло­ва­ми рус­ско­го языка."; 
    $self->{correct} = $ans;
}
1;