# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::Sorting;
use base 'EGE::GenBase::Sortable';

use strict;
use warnings;
use utf8;

use EGE::Html;
use EGE::Random;
use EGE::Prog::Alg;
use EGE::Prog;


sub first_space {
    my $i = -1;
    1 while substr($_[0], ++$i, 1) eq ' ';
    $i;
}

sub sort_line {
    # не используется construct, потому что на Basic'е end выглядят по разному
    my ($self) = @_;
    $self->{text} = "Отсортируйте строки таким образом, чтобы они образовали алгоритм сортировки " .
        "массива <code>a</code>, длинной <code>n</code>." .
        "<p><i>Прим1.</i> Начало и конец условных операторов и операторов цикла должны иметь одинаковый цвет, " .
        "недопустимо использовать начало и конец разного цвета, даже если они имеют одинаковый текст.</p>" .
        "<p><i>Прим2.</i> Индексация массивов на всех языках начинается с <code>0</code> и " .
        "заканчивается <code>n-1</code>.</p>";

    my $b = rnd->pick(values %EGE::Prog::Alg::sortings);
    my $fst_color = rnd->in_range(0 .. 11);
    for my $lang (qw(Basic C Alg Pascal))
    {
        my $code = EGE::Prog::make_block($b)->to_lang_named($lang, { 
                html => {
                    coloring => $fst_color,
                    lang_marking => 1,
                },
                body_is_block => 1,
                lang_marking => 1,
                unindent => 1,
            });
        my @cur_v = split '\n', $code;
        $self->{variants}->[$_] .= $cur_v[$_] for 0 .. scalar(@cur_v) - 1;
    }
    $self->{correct} = [ 0 .. scalar(@{$self->{variants}}) - 1 ];
    $self->{langs} = [ qw(Basic C Alg Pascal) ];
    1;
}
1;
