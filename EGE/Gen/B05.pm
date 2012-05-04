# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B05;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;

use EGE::Gen::A17;

my @commands = (
    sub {
        my $v = rnd->in_range(1, 9);
        "прибавь $v",
        "прибавляет к числу на экране $v",
        "прибавляет к нему $v",
        sub { $_[0] + $v }
    },
    sub {
        my $v = rnd->in_range(2, 5);
        "умножь на $v",
        "умножает число на экране на $v",
        "умножает его на $v",
        sub { $_[0] * $v }
    },
    sub {
        'возведи в квадрат',
        'возводит число на экране в квадрат',
        'возводит его в квадрат',
        sub { $_[0] * $_[0] }
    },
);

sub make_cmd {
    my %cmd;
    @cmd{qw(t1 t2 t3 run)} = $_[0]->();
    \%cmd;
}

sub apply {
    my ($cmd, $prg, $value) = @_;
    $value = $cmd->[$_]->{run}->($value) for @$prg;
    $value;
}

sub next_prg {
    my ($cmd, $prg) = @_;
    for (@$prg) {
        return 1 if ++$_ < @$cmd;
        $_ = 0;
    }
    0;
}

sub code { join '', map $_ + 1, @{$_[0]}; }
sub li { join '', map "<li>$_</li>", @_; }

sub same_digit { $_[0] =~ /^(\d)\1+$/; }

sub calculator {
    my ($self) = @_;
    my $num = rnd->in_range(4, 6);

    my ($cmd, $arg, $prg, $result);
    do {
        $cmd = [ map make_cmd($_), rnd->pick_n(2, @commands) ];
        $arg = rnd->in_range(2, 10);
        $prg = [ (0) x $num ];
        my %results;
        do {
            ++$results{apply($cmd, $prg, $arg)}
        } while next_prg($cmd, $prg);
        my @r = grep 50 < $_ && $_ < 1000 && $results{$_} == 1, keys %results;
        $result = rnd->pick(@r) if @r;
    } until $result;
    $prg = [ (0) x $num ];
    next_prg($cmd, $prg) until apply($cmd, $prg, $arg) == $result;
    my $code = code($prg);

    my ($sample_prg, $sample_code, $sample_result);
    do {
        $sample_prg = [ map rnd->in_range(0, $#$cmd), 1 .. $num ];
        $sample_code = code($sample_prg);
        $sample_result = apply($cmd, $sample_prg, 1);
    } while
        $sample_code eq $code ||
        $sample_result eq $result ||
        same_digit($sample_code);

    my @sample_prg_list = map $cmd->[$_]->{t1}, @$sample_prg;
    $sample_prg_list[-1] .= ',';

    $self->{text} =
        'У исполнителя Калькулятор две команды, которым присвоены номера: ' .
        '<b><ol> ' . li(map ucfirst($_->{t1}), @$cmd) . '</ol></b> ' .
        "Выполняя первую из них, Калькулятор $cmd->[0]->{t2}, " .
        "а выполняя вторую, $cmd->[1]->{t3}. " .
        "Запишите порядок команд в программе получения из числа $arg " .
        "числа $result, содержащей не более $num команд, указывая лишь номера команд " .
        "(Например, программа $sample_code — это программма " .
        '<b><ul> ' . li(@sample_prg_list) . '</ul></b> ' .
        "которая преобразует число 1 в число $sample_result)";
    $self->{correct} = $code;
    $self->accept_number;
}

sub _char_to_int {
    ord(substr($_[0], 1, length($_[0]) - 1)) - ord('A');
}

sub _to_formula {
    my ($str, $perm_alph) = @_;
    $str =~ s/(\%\w+)/$perm_alph->[_char_to_int($1)]/ge;
    '=' . $str
}

sub _apply_perm {
    my ($array, $perm) = @_;
    [map { $array->[$_] } @$perm];
}

sub _back_perm {
    my ($perm) = @_;
    my %h;
    for my $i (0 .. $#{$perm}) {
        $h{$perm->[$i]} = $i
    }
    [ map { $h{$_} } sort { $a <=> $b } keys %h ]
}

sub complete_spreadsheet {
    my ($self) = @_;

    my $table = rnd->pick(
        { 1    => [3, 2, 3, 2],
          2    => ["(%C+%A)/2", "%C-%D", "%A-%D", "%B/2"],
          ans  => [3, 1, 1, 1],
          find => 1 }
    );

    my $n = @{$table->{1}};
    my $perm_1 = [rnd->shuffle(0 .. $n -1)];
    my $perm_1_back = _back_perm($perm_1);
    my $perm_2 = [rnd->shuffle(0 .. $n -1)];
    my $perm_alph = _apply_perm(['A' .. 'Z'], $perm_1_back);

    my $new_table =
    {
       1    => _apply_perm($table->{1}, $perm_1),
       2    => _apply_perm($table->{2}, $perm_2),
       ans  => _apply_perm($table->{ans}, $perm_2),
       find => $perm_1_back->[$table->{find}]
    };
    $self->{correct} = $new_table->{1}[$new_table->{find}];
    $new_table->{1}[$new_table->{find}] = '';
    my $empty_ceil_text = ['A' .. 'Z']->[$new_table->{find}] . 1;

    $_  = html->row('th', html->nbsp, 'A' .. chr(ord('A') + $n - 1));
    $_ .= html->row('td', '<strong>1</strong>', @{$new_table->{1}});
    $_ .= html->row('td', '<strong>2</strong>',
                    map { _to_formula($_, $perm_alph) } @{$new_table->{2}});
    my $table_text = html->table($_, {border => 1});
    my $chart = EGE::Gen::A17::pie_chart($new_table->{ans}, 100);
    my $last_letter = ['A' .. 'Z']->[$n - 1];
    $self->{text} = "Дан фрагмент электронной таблицы: $table_text" .
        "Какое число  должно быть записано в ячейке $empty_ceil_text, чтобы " .
        "построенная после выполнения вычислений диаграмма по значениям " .
        "диапазона ячеек A2:${last_letter}2 соответствовала рисунку? $chart";
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item calculator

=item min_routes

=back


=head2 Генератор complete_spreadsheet

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание B5.

=head3 Описание

Разные вариатны задания (значения в ячейках и формулы) составляются вручную.
Чтобы разнообразить получаемый текст, значений в 1й и 2й строках таблицы
перемешиваются, в соответствии с этим автоматически меняются буквы в формулах.

=head2 Формат варианта задания

    { 1    => [3, 2, 3, 2],
      2    => ["(%C+%A)/2", "%C-%D", "%A-%D", "%B/2"],
      ans  => [3, 1, 1, 1],
      find => 1 }

=over

Подробнее:

=item Числовые значения в первой строке

    { 1    => [3, 2, 3, 2],

Одно значение, являющееся ответом, будет скрыто

=item Формулы во второй строке

      2    => ["(%C+%A)/2", "%C-%D", "%A-%D", "%B/2"],

Символами %A, %B, ... обозначаются ссылки на 1ю, 2ю, ...  ячейки в 1й строке.

=item Результаты вычисления формул во 2й строке

      ans  => [3, 1, 1, 1],

По этим значениям строится диаграмма.

=item Номер(с нуля) ячейки из 1й строку, которую нужно скрыть

      find => 1 }

=back

Размерность раблицы по горизонтали: от 1 до 26.
