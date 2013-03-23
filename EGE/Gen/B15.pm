# Copyright © 2010-2012 Alexander S. Klenin
# Copyright © 2012 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::B15;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub _connect {
    my @x = map { "x<sub>$_</sub>" } @_;
    "(($x[0] ≡ $x[1]) \\/ ($x[2] ≡ $x[3])) /\\ (¬($x[0] ≡ $x[1]) \\/ ¬($x[2] ≡ $x[3])) = 1"
}

sub logic_var_set {
    my ($self) = @_;
    my $n_2 = rnd->in_range(4, 8);
    $self->{correct} = 2**($n_2 + 1);
    $self->accept_number();
    my $connections = join '<br/>', map { _connect($_, $_ + 1, $_ + 2, $_ + 3) }
        map { 2*$_ + 1 }  0 .. $n_2 - 2;
    my $vars = join ', ', map { "x<sub>$_</sub>" } 0 .. 2*$n_2;
    $self->{text} = <<EOL
Сколько существует различных наборов значений логических переменных <em>$vars</em> которые
удовлетворяют всем перечисленным ниже условиям? <p><em>$connections</em></p> В ответе
<strong><u>не нужно</u></strong>
перечислять все различные наборы значений <em>$vars</em>, при которых выполнена данная
система равенств. В качестве ответа вам нужно указать количество таких наборов.
EOL
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item logic_var_set 

=back


=head2 Генератор logic_var_set

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание B15.

=head3 Описание

Решение:

=over

=item *

Для начала рассмотрим случай 4х переменных:

    ((x1 ≡ x2) \/ (x3 ≡ x4)) /\ (¬(x1 ≡ x2) \/ ¬(x3 ≡ x4)) = 1

Уравнение выше можно записать так:

    x1 = x2 <=> x3 != x4
    x1 != x2 <=> x3 = x4

8 наборов переменных удовлетворяют этому уравнению.

=item *

Теперь переходим к случаю 6ти перменых:
Для каждого из уже выбранных наборов для случая 4х переменных можем добавить по 2 набора
из x5, x6

=item *

Для n = 2*k получаем:

Всего k-1 пар. Первая пара даёт 8 вариантов, каждая последующая увеличивает число
вариантов вдвое. Имеем:

    8 * 2 ^ ( k - 2 ) = 2 ^ ( k + 1)

=back
