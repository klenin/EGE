# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A07;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use List::Util;

use EGE::Random;
use EGE::Logic;
use EGE::NumText;
use EGE::Russian::Names;
use EGE::Russian::SimpleNames;
use EGE::Russian::Animals;
use EGE::Bits;


sub make_condition() {
    {
        n => rnd->in_range(1, 5),
        type => (rnd->in_range(1, 6) > 1 ? 1 : 2),
        vc => rnd->coin,
    }
}

sub cond_to_text {
    my ($cond) = @_;
    my @pos_names = qw(Первая Вторая Третья Четвёртая Пятая Шестая);
    my @count_names = qw(одна две три четыре пять шесть);
    my @letters = ('гласная буква', 'гласных буквы', 'гласных букв');

    my $vc = $cond->{vc} ? 'со' : '';
    $cond->{type} == 1 ?
        $pos_names[$cond->{n} - 1]  . " буква ${vc}гласная" :
        'В слове ' . num_text($cond->{n}, [ map "$vc$_", @letters ]);
}

sub letter_vc { substr($_[0], $_[1], 1) =~ /[аеёиоуыэюя]/i ? 0 : 1; }
sub count_vc { 0 + grep letter_vc($_[0], $_) == $_[1], 0 .. length($_[0]) - 1 }

sub check_cond {
    my ($cond, $str) = @_;

    my $vc = $cond->{vc}; 
    my $r = $cond->{type} == 1 ?
        letter_vc($str, $cond->{n} - 1) == $vc :
        $cond->{n} == count_vc($str, $vc);
    $r ? 1 : 0;
}

sub cond_eq {
    my ($cond1, $cond2) = @_;
    for (keys %$cond1) {
        return 0 if $cond1->{$_} ne $cond2->{$_};
    }
    1;
}

sub check_good {
    my ($tf) = @_;
    for (rnd->shuffle(0, 1)) {
        return $_ if @{$tf->[$_]} && @{$tf->[1 - $_]} >= 3;
    }
    -1;
}

sub make_cond_group {
    my $g = { size => rnd->pick(2, 3) };
    my $v = $g->{vars} = [ (0) x $g->{size} ];
    $g->{expr} = EGE::Logic::random_logic_expr(map \$_, @$v);
    my $c = $g->{cond} = [ make_condition ];
    for (2 .. $g->{size}) {
        my $new_cond;
        do {
            $new_cond = make_condition;
        } while grep cond_eq($_, $new_cond), @$c;
        push @$c, $new_cond;
    }
    $v->[$_] = cond_to_text($c->[$_]) for 0 .. $g->{size} - 1;
    $g->{text} = $g->{expr}->to_lang_named('Logic');
    $g->{min_len} = List::Util::max(map $_->{n}, @$c);
    $g;
}

sub check_cond_group {
    my ($g, $str) = @_;
    $g->{vars}->[$_] = check_cond($g->{cond}->[$_], $str)
        for 0 .. $g->{size} - 1;
    $g->{expr}->run({}) ? 1 : 0;
}

sub strings {
    my ($self, $init_string, $next_string, $list_text) = @_;
    my $good = -1;
    my $true_false;
    my $g;
    do {
        $g = make_cond_group;
        $true_false = [ [], [] ];
        $init_string->();
        while(my $str = $next_string->()) {
            next if length($str) < $g->{min_len};
            push @{$true_false->[check_cond_group($g, $str)]}, $str;
            $good = check_good($true_false);
        }
    } while $good < 0;
    my $tf = $good ? 'истинно' : 'ложно';

    $self->{text} = "Для какого $list_text $tf высказывание:<br/>$g->{text}?";
    $self->variants($true_false->[$good][0], @{$true_false->[1 - $good]}[0 .. 2]);
}

sub names {
    my ($self) = @_;
    my @list = rnd->shuffle(@EGE::Russian::Names::list);
    my $i;
    $self->strings(sub { $i = 0 }, sub { $list[$i++] }, 'имени');
}

sub animals {
    my ($self) = @_;
    my @list = rnd->shuffle(@EGE::Russian::Animals::list);
    my $i;
    $self->strings(sub { $i = 0 }, sub { $list[$i++] }, 'из названий животных');
}

sub random_sequences {
    my ($self) = @_;
    my %seen;
    my $gen_seq = sub {
        my $r;
        do {
            $r = join '', map uc rnd->pretty_russian_letter, 1..6;
        } while $seen{$r}++;
        return if keys %seen > 100;
        $r;
    };
    $self->strings(sub { %seen = () }, $gen_seq, 'символьного набора');
}

sub rnd_subpattern {
    my ($last_prn) = $_[0] || '';
    my $res;
    do {
        $res = uc(rnd->english_letter()) . rnd->in_range(0, 9)
    } while $res eq $last_prn;
    $res;
}

sub delete_nums {
    my ($str) = @_;
    $str = " $str ";
    my (@good_variants, @bad_variants);
    for my $len (1 .. length $str) {
        my @pos;
        push @pos, pos($str)-- - $len - 1 while $str =~ /(\D)\d{$len}(\D)/g;
        next unless @pos;

        my $per = EGE::Bits->new();
        $per->set_size(scalar @pos);
        # генерация всех подмножеств множества перечисленим двоичных векторов
        for (2 .. 2**@pos) {
            $per->inc();
            my $s = $str;
            for (my $i = $#pos; $i >= 0; --$i) {
                if ($per->get_bit($i)) {
                    substr($s, $pos[$i], $len, '');
                }
            }
            push @bad_variants, $s;
        }
        push @good_variants, [pop (@bad_variants), $len];
    }
    (\@good_variants, \@bad_variants);
}

sub restore_password {
    my ($self) = @_;
    my $str = join '', map { rnd->pick('A'..'F', 0..9) } 1..5;
    my $init_str = $str;
    # Сгенерируем 2 разные маленькие строки из 2х символов: буква + цифра.
    my $sub_init = rnd_subpattern();
    my $sub_good = rnd_subpattern($sub_init);

    # Вставим в разные копии одной строки в 2 позиции маленькие строки.
    # Для полученных строк выполняется: $str получается из $init_str заменой
    # $sub_init на $sub_good
    my @pos = sort { $b <=> $a } rnd->pick_n(2, 0 .. (length $str) - 1);
    for (@pos) {
        substr($str, $_, 0, $sub_good);
        substr($init_str, $_, 0, $sub_init);
    }
    $str =~ s/$sub_init/$sub_good/;

    # Удалив полностью и частично цифры из строк получим варианты ответов
    my ($good_variants, $bad_variants) = delete_nums($str);
    my ($bad_variants2, $bad_variants3) = delete_nums($init_str);

    rnd->shuffle(@{$good_variants});
    my $ans = shift @{$good_variants};

    @{$self->{variants}} = (
       @{$bad_variants},
       (map {$_->[0]} @{$good_variants}),
       @{$bad_variants3},
       (map {$_->[0]} @{$bad_variants2})
   );

    @{$self->{variants}} = ($ans->[0], rnd->pick_n(3, @{$self->{variants}}));

    my $OS = rnd->pick("Windows XP", "GNU/Linux", "почтовый аккаунт");
    $self->{text} .=
      rnd->pick(@EGE::Russian::SimpleNames::list) .
      " забыл пароль для входа в $OS, но помнил алгоритм его " .
      "получения из символов «$init_str» в строке подсказки. Если " .
      "последовательность символов «$sub_init» заменить на «$sub_good» " .
      "и из получившейся строки удалить все ".
      ($ans->[1] == 1 ? "одно" : (num_by_words $ans->[1], 1, "genitive")) .
      "значные числа, то полученная последовательность и " .
      "будет паролем: ";
}

sub _move {
    my ($ceil, $hold_x, $hold_y, $dx, $dy) = @_;
    my ($x, $y) = @{$ceil}{qw(x y)};
    $x += $dx unless $hold_x;
    $y += $dy unless $hold_y;
    {x => $x, y => $y}
}

sub _all_moves {
    my ($ceil, $hold_x, $hold_y, $dx, $dy) = @_;
    my @res = (_move($ceil, $hold_x, $hold_y, $dx, $dy));
    if ($dx) {
        push @res, _move($ceil, !$hold_x, $hold_y, $dx, $dy);
    }
    if ($dy) {
        push @res, _move($ceil, $hold_x, !$hold_y, $dx, $dy);
    }
    if ($dx && $dy) {
        push @res, _move($ceil, !$hold_x, !$hold_y, $dx, $dy);
    }
    \@res
}

my @alph = ('A' .. 'Z');

sub _print_ceil {
    my ($ceil, $hold_x, $hold_y, $suffix) = @_;
    join '', ($hold_y ? '$' : ''), $alph[$ceil->{y}],
             ($hold_x ? '$' : ''), $ceil->{x},
             ($suffix // '')
}

sub _rnd_ceil { { x => rnd->in_range(4, 10), y => rnd->in_range(4, 10) } }

sub _ceil_eq { $_[0]->{x} == $_[1]->{x} && $_[0]->{y} == $_[1]->{y} }

sub _gen_params {
    my ($c) = @_;
    my $d = rnd->in_range(1, 3);

    $c->{moves} = [ rnd->shuffle([$d, $d], [-$d, $d], [$d, -$d], [-$d, -$d],
                                 [$d, 0], [-$d, 0], [0, $d], [0, -$d]) ];

    my ($hold_x, $hold_y);
    do {
        ($hold_x, $hold_y) = (rnd->coin(), rnd->coin())
    } while (!$hold_x && !$hold_y);
    @{$c}{qw(ceil hold_x hold_y)} = (_rnd_ceil(), $hold_x, $hold_y);
    my ($from_ceil, $to_ceil);
    do {
        $c->{from_ceil} = _rnd_ceil();
        $c->{to_ceil} = _move($c->{from_ceil}, 0, 0, @{ $c->{moves}[0] });
    } while (_ceil_eq($c->{ceil}, $c->{from_ceil}) |
             _ceil_eq($c->{ceil}, $c->{to_ceil}));

    $c->{suffix} = rnd->pick(' + ', ' - ', ' * ', ' / ') .
                   rnd->in_range(1 .. 9);
}

sub _gen_task {
    my ($c) = @_;
    my @res;
    my $i = 0;
    while (@res < 4) {
        for my $p (@{ _all_moves(@{$c}{qw(ceil hold_x hold_y)},
                                 @{ $c->{moves}[$i] }) })
        {
            push @res, $p unless grep { _ceil_eq($p, $_) } @res
        }
        ++$i;
    }
    $c->{result} = [@res[0 .. 3]]
}

sub spreadsheet_shift {
    my ($self) = @_;

    my $context = {};
    _gen_params($context);
    _gen_task($context);

    $self->variants(
        map { _print_ceil($_, @{$context}{qw(hold_x hold_y suffix)}) }
            @{$context->{result}}
    );

    $self->{text} .= sprintf
        'В ячейке %s электронной таблицы записана формула = %s. Какой вид ' .
        'приобретет формула, после того как ячейку %s скопируют в ячейку %s?' .
        'Примечание: знак $ используется для обозначения абсолютной адресации.',
        _print_ceil($context->{from_ceil}),
        _print_ceil(@{$context}{qw(ceil hold_x hold_y suffix)}),
        _print_ceil($context->{from_ceil}),
        _print_ceil($context->{to_ceil})
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item names

=item animals

=item random_sequences

=item restore_password

=item spreadsheet_shift

=back


=head2 Генератор spreadsheet_shift

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание A07.

=head3 Описание

=over

=item *

Выбираются начальные параметры:
Какие координаты зафиксированы; направление сдвига из 8ми возможных (4 по горизонтали, 4 по диагонали).

=item *

Производится сдвиг. Варируя фиксаторы координат получается еще несколько
неверных значений. Если значений не хватает выбирается другое направление
сдвига и таким же образом генерируются неверные результаты.

=back
