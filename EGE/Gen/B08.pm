# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B08;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub identify_letter {
    my ($self) = @_;
    my $n = rnd->in_range(6, 10);
    my $dn = rnd->in_range(1, $n - 1);
    my $dx = rnd->in_range(1, $n - $dn);

    $self->{text} .= <<QUESTION
Строки (цепочки символов латинских букв) создаются по следующему
правилу.
Первая строка состоит из одного символа – латинской буквы «А». Каждая из
последующих цепочек создается такими действиями: в очередную строку
сначала записывается буква, чей порядковый номер в алфавите
соответствует номеру строки (на i-м шаге пишется i-я буква алфавита), к ней
слева дважды подряд приписывается предыдущая строка.
Вот первые 4 строки, созданные по этому правилу:
<ol>
<li>A</li>
<li>AAB</li>
<li>AABAABC</li>
<li>AABAABCAABAABCD</li>
</ol>
<p><i><b>Латинский алфавит (для справки)</b></i>:
ABCDEFGHIJKLMNOPQRSTUVWXYZ</p>
Имеется задание:
«Определить символ, стоящий в n-й строке на позиции
<strong>2<sup>n - $dn</sup> – $dx</strong>, считая от
левого края цепочки».
<br/>Выполните это задание для <strong>n = $n</strong>
QUESTION
;
    $self->{correct} = ['A' .. 'Z']->[$n - $dn - $dx];
}



1;
