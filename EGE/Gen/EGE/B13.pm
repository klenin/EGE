# Copyright © 2010-2012 Alexander S. Klenin
# Copyright © 2012 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::EGE::B13;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;

sub plus_minus {
    my ($self) = @_;
    my ($a, $b) = map { rnd->in_range(1, 9) } 1, 2;
    my $cmd_cnt = rnd->in_range(5, 10);
    $self->{correct} = $cmd_cnt + 1;
    $self->accept_number();

    my ($act1, $act2) = rnd->shuffle([qw(увеличивает прибавь)],
                                     [qw(уменьшает вычти)]);
    my $list = html->ol( html->li("$act1->[1] $a") .
                         html->li("$act2->[1] $b") );
    my $actor = rnd->pick([qw(Кузнечик Кузнечика)],
                          [qw(Человечик Человечика)],
                          [qw(Калькулятор Калькулятора)],
                          [qw(Преобразователь Преобразователя)],
                          [qw(Вычислитель Вычислителя)]);
    my $start = rnd->in_range(0, 10);
    $self->{text} = <<EOL
У исполнителя $actor->[0] две команды: <b>$list</b> Первая из них $act1->[0] число на экране
на $a, вторая – $act2->[0] его на $b (отрицательные числа допускаются). Программа
для $actor->[1] – это последовательность команд. Сколько различных чисел
можно получить  из числа $start с помощью программы, которая содержит ровно
$cmd_cnt команд?
EOL
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item plus_minus

=back


=head2 Генератор plus_minus

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание B13.

=head3 Описание

Особенности задания:
Использутеся только сложение и вычитание, следовательно  порядок применения операций не
важен. Результат зависит только от количества применений 1й или 2й операции.
