# Copyright © 2010-2012 Alexander S. Klenin
# Copyright © 2012 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::B12;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;

use List::Util 'min';

sub search_query {
    my ($self) = @_;
    my ($item1, $item2) = rnd->pick_n(2, qw(Шахматы Теннис Волейбол Хоккей Футбол
                                            Плавание Баскетбол Дартс Гольф Биатлон));
    my ($item1_cnt, $item2_cnt) = map { 10 * rnd->in_range(200, 999) } 1, 2;
    my $both_cnt = 10 * rnd->in_range(100, int min($item1_cnt, $item2_cnt)/20);

    my @variants = (["$item1 | $item2", $item1_cnt + $item2_cnt - $both_cnt],
                    ["$item1", $item1_cnt],
                    ["$item2", $item2_cnt],
                    ["$item1 &amp; $item2", $both_cnt]);

    my $to_find = splice @variants, rnd->in_range(0, 3), 1;
    $self->{correct} = $to_find->[1];

    $_ = html->row('th', '<b>Запрос</b>', '<b>Найдено страниц (в тысячах)</b>');
    $_ .= join '', map { html->row('td', @$_) } @variants;
    my $table = html->table($_, { border => 1, style => 'text-align: center' });
    $self->{text} = <<EOL
В языке запросов поискового сервера для обозначения логической операции «ИЛИ»
используется символ «|», а для логической операции «И» – символ «&amp;».
В таблице приведены запросы и количество найденных по ним страниц некоторого
сегмента сети Интернет. 
$table
Какое количество страниц (в тысячах) будет найдено по запросу<br/>
<i><b>$to_find->[0]?</b></i><br/>
Считается, что все запросы выполнялись практически одновременно, так что набор
страниц, содержащих все искомые слова, не изменялся за время выполнения запросов.
EOL
}

1;
