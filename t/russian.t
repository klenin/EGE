use strict;
use warnings;
use utf8;

use Test::More tests => 47;

use lib '..';
use EGE::Russian::Animals;
use EGE::Russian::Names;
use EGE::Russian::SimpleNames;

{
    my %h; undef @h{@EGE::Russian::alphabet};
    is scalar keys %h, 33, 'alphabet';
}

is 'a', EGE::Russian::join_comma_and('a'), 'join a';
is 'a и b', EGE::Russian::join_comma_and('a', 'b'), 'join a b';
is 'a, b и c', EGE::Russian::join_comma_and('a', 'b', 'c'), 'join a b c';

for (1..5) {
    my ($n1, $n2) = EGE::Russian::Names::different_males(2);
    isnt substr($n1, 0, 1), substr($n2, 0, 1), "different_males $_";
}

for (1..5) {
    my ($n1, $n2) = EGE::Russian::Names::different_names(2);
    isnt substr($n1->{name}, 0, 1), substr($n2->{name}, 0, 1), "different_names $_";
}

is EGE::Russian::SimpleNames::genitive('Вий'), 'Вия', 'SimpleNames::genitive';

{
    my $n = [
        [ 'Валерий', 'Валерия' ],
        [ 'Игорь', 'Игоря' ],
        [ 'Альфреа', 'Альфреи' ],
        [ 'Ядвига', 'Ядвиги' ],
        [ 'Лука', 'Луки' ],
        [ 'Анжелика', 'Анжелики' ],
        [ 'Кузьма', 'Кузьмы' ],
        [ 'Глория', 'Глории' ],
        [ 'Лев', 'Льва' ],
    ];

    is EGE::Russian::Names::genitive($n->[$_][0]), $n->[$_][1], 'Names::genitive ' . ($_ + 1) for 0..$#$n;
}

{
    my $n = [
        [ 'Валерий', 'Валерием' ],
        [ 'Игорь', 'Игорем' ],
        [ 'Альфреа', 'Альфреей' ],
        [ 'Ядвига', 'Ядвигой' ],
        [ 'Лука', 'Лукой' ],
        [ 'Анжелика', 'Анжеликой' ],
        [ 'Кузьма', 'Кузьмой' ],
        [ 'Глория', 'Глорией' ],
        [ 'Лев', 'Львом' ],
        [ 'Илья', 'Ильёй' ],
        [ 'Наталья', 'Натальей' ],
    ];

    is EGE::Russian::Names::ablative($n->[$_][0]), $n->[$_][1], 'Names::ablative ' . ($_ + 1) for 0..$#$n;
}

{
    my $n = [
        [ 'Валерий', 'Валерию' ],
        [ 'Игорь', 'Игорю' ],
        [ 'Альфреа', 'Альфрее' ],
        [ 'Ядвига', 'Ядвиге' ],
        [ 'Анжелика', 'Анжелике' ],
        [ 'Кузьма', 'Кузьме' ],
        [ 'Глория', 'Глории' ],
        [ 'Лев', 'Льву' ],
        [ 'Илья', 'Илье' ],
        [ 'София', 'Софии' ],
        [ 'Архип', 'Архипу' ],
    ];

    is EGE::Russian::Names::dative($n->[$_][0]), $n->[$_][1], 'Names::dative ' . ($_ + 1) for 0..$#$n;
}

is grep($_ eq 'Лемур', @EGE::Russian::Animals::distinct_letters), 1, 'distinct_letters';

