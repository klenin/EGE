package EGE::Gen::A01;

use strict;
use warnings;
use utf8;

use Encode;

use EGE::Random;
use EGE::NumText;

sub bits_or_bytes { rnd->pick(bits_and_bytes($_[0])) }

sub recode {
    my $delta = rnd->pick(8, 16, 32, map $_ * 10, 1..10);
    my $dir = rnd->pick(
      { from => '16-битной кодировке UCS-2', to => '8-битную кодировку КОИ-8', change => 'уменьшилось' },
      { from => '8-битной кодировке КОИ-8', to => '16-битную кодировку UCS-2', change => 'увеличилось' },
    );
    my $delta_text = bits_or_bytes($delta);
    my $q = <<QUESTION
Автоматическое устройство осуществило перекодировку информационного сообщения,
первоначально записанного в $dir->{from}, в $dir->{to}.
При этом информационное сообщение $dir->{change} на $delta_text.
Какова длина сообщения в символах?
QUESTION
;
    {
        question => $q,
        variants => [ $delta * 8, $delta, int($delta / 2), $delta * 16 ],
        answer => 1,
        variants_order => 'random',
    };
}

sub simple {
    my $enc = rnd->pick(
        { name => 'UCS-2', size => 2 }, 
        { name => 'КОИ-8', size => 1 }, 
        { name => 'CP1251', size => 1 },
    );
    my @size_names = (
        [ '1 байтом', '8 битами' ],
        [ '2 байтами', '16 битами' ],
    );
    my $size_name = rnd->pick(@{$size_names[$enc->{size} - 1]});
    my $text = rnd->pick(
        'Известно, что Слоны в диковинку у нас.',
        'У сильного всегда бессильный виноват.',
        'Попрыгутья Стрекоза лето красное пропела',
    );
    my $q = <<QUESTION
В кодировке $enc->{name} каждый символ кодируется $size_name. Определите объём
следующего предложения в данном представлении: <b>$text</b>.
QUESTION
;
    my $len = length $text;
    my $text_nosp = $text;
    $text_nosp =~ s/ //g;
    my $len_nosp = length $text_nosp;
    {
        question => $q,
        variants => [ map bits_or_bytes($_), $len, 2 * $len, int($len / 8), $len_nosp ],
        answer => $enc->{size} - 1,
        variants_order => 'random',
    };
}

1;
