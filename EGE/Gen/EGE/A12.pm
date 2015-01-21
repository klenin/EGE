# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A12;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;

sub except {
    my ($all, $except) = @_;
    my %h;
    @h{@$all} = undef;
    delete $h{$_} for @$except;
    keys %h;
}

sub beads {
    my ($self) = @_;
    my @all = rnd->pick_n_sorted(5, 'A' .. 'Z');
    my $len = 3;
    my @order = rnd->shuffle(0 .. $len - 1);
    my @subsets = map [ rnd->pick_n_sorted(rnd->pick(3, 4), @all) ], 1 .. $len;

    my $gen = sub {
        my ($bad_stage) = @_;
        my $letter = $bad_stage ? '' : rnd->pick(except \@all, $subsets[0]);
        my @r;
        for my $i (0 .. $len - 1) {
            $letter = rnd->pick(grep $_ ne $letter, @{$subsets[$i]})
                if $bad_stage != $i;
            $r[$order[$i]] = $letter;
        }
        join '', @r;
    };

    my @one_of_beads = map 'одна из бусин ' . join(', ', @$_), @subsets;

    my @pos_names = (
        [ 'в начале цепочки', 'на первом месте', ],
        [ 'в середине цепочки', 'на втором месте', ],
        [ 'в конце цепочки', 'на последнем месте', 'на третьем месте', ],
    );
    my $pos_name = sub { rnd->pick(@{$pos_names[$order[$_[0]]]}) };

    my $rule = ucfirst($pos_name->(0)) . " стоит $one_of_beads[0]. ";
    for (1 .. $len - 1) {
        $rule .=
            sprintf '%s — %s, %s %s. ',
            ucfirst($pos_name->($_)), $one_of_beads[$_],
            rnd->pick('которой нет', 'не стоящая'), $pos_name->($_ - 1);
    }

    $self->{text} =
        'Цепочка из трёх бусин, помеченных латинскими буквами, ' .
        "формируется по следующему правилу. $rule" .
        'Какая из перечисленных цепочек создана по этому правилу?';
    $self->variants(map $gen->($_ - 1), 0 .. $len);
}

sub array_flip {
    my ($self) = @_;
    my $n = rnd->in_range(8, 12);
    my ($i, $k) = rnd->index_var(2);
    my $init_op = rnd->pick(
        ['=', [ '[]', 'A', $i ], [ '-', $n - 1, $i ]],
        ['=', [ '[]', 'A', $i ], $i ]
    );
    my $A_i = [ '[]', 'A', $i ];
    my $A_ni = ['[]', 'A', ['-', ($n - 1), $i ] ];
    ($A_i, $A_ni) = ($A_ni, $A_i) if rnd->coin();
    my $b = EGE::Prog::make_block([
        'for', $i, 0, $n - 1, $init_op,
        'for', $i, 0, int(($n - 1) / 2), [
            ('=', $k, $A_i),
            ('=', $A_i, $A_ni),
            ('=', $A_ni, $k),
        ],
    ]);
    my $lt = EGE::LangTable::table($b, [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C' ] ]);
    my @ar_val = @{$b->run_val('A')};
    my @bad1 = ((0 .. ($n-1)/2), reverse (0 .. ($n/2-1)));
    my @bad2 = $n % 2 ?
        ((reverse 0 .. ($n-1)/2), 1 .. ($n-1)/2 ) :
        ((reverse 0 .. ($n-1)/2), 0 .. ($n-1)/2 );
    $self->variants(map { join ' ', @$_ }
                    \@ar_val,
                    [reverse @ar_val],
                    \@bad1,
                    \@bad2);
    $self->{text} = sprintf
        'В программе используется одномерный целочисленный массив A с индексами ' .
        'от 0 до %s. Ниже представлен фрагмент программы, записанный на ' .
        'разных языках программирования, в котором значения элементов сначала ' .
        'задаются, а затем меняются. %s Чему будут равны элементы этого массива ' .
        'после выполнения фрагмента программы?', $n - 1, $lt;
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item beads

=item array_flip

=back


=head2 Генератор array_flip

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание A12.

=head3 Описание

Ограничение на размерность массива 8 .. 12 = 10(в оригинале условия) +- 2.

Для разнообразия в задание добавлено:

=over

=item 1

Инициализация массива целими числами: n-1 .. 0 (а не 0 .. n-1)

=item 2

Обратный порядок присваиваний при перестановке элементов в массиве

=back
