package EGE::Russian::SimpleNames;

use strict;
use warnings;
use utf8;

use base 'Exporter';
our @EXPORT_OK = qw(genitive);

our @list =
qw(
Александр
Алексей
Анатолий
Андрей
Антон
Аркадий
Артём
Борис
Вадим
Василий
Виктор
Виталий
Владимир
Вячеслав
Геннадий
Георгий
Глеб
Григорий
Денис
Дмитрий
Евгений
Егор
Иван
Кирилл
Константин
Леонид
Михаил
Николай
Олег
Петр
Роман
Семён
Сергей
Степан
Тимофей
Федор
Эдуард
Юрий
Яков
);

sub genitive {
    my $name = shift;
    for ($name) {
        /й$/ ? s/й$/я/ : ($_ .= 'а');
    }
    $name;
}

1;
