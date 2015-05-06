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
    my @colors = qw(blue fuchsia green maroon navy olive purple red silver teal yellow);
    $self->{text} = "Отсортируйте строки таким образом, чтобы они образовали алгоритм сортировки " .
        "массива <code>a</code>, длинной <code>n</code>." .
        "<p><i>Прим1.</i> Начало и конец условных операторов и операторов цикла должны иметь одинаковый цвет, " .
        "недопустимо использовать начало и конец разного цвета, даже если они имеют одинаковый текст.</p>" .
        "<p><i>Прим2.</i> Индексация массивов на всех языках начинается с <code>0</code> и " .
        "заканчивается <code>n-1</code>.</p>";

    my $b = rnd->pick(values %EGE::Prog::Alg::sortings);

    for my $lang (qw(Basic C Alg Pascal))
    {
        my @lines = split '\n', EGE::Prog::make_block($b)->to_lang_named($lang, 1);
        my @copy = @lines;
        $_ =~ s/^ +// for @copy;
        my @vars =  map html->pre($_, { class => $lang }), @copy;
        for my $i (0 .. @vars - 2) {
            my ($fst, $sec) = map first_space($lines[$_]), ($i, $i + 1);
            my ($index, $num) = $fst < $sec ? ($i, $fst) : ($i + 1, $sec);
            my $attr = {
                style => "color: $colors[$num / 2]",
                class => $lang
            };
            $vars[$index] = html->pre($copy[$index], $attr) if $fst != $sec;
        }
        $self->{variants}->[$_] .= $vars[$_] for 0 .. scalar(@vars) - 1;
    }
    $self->{correct} = [ 0 .. scalar(@{$self->{variants}}) - 1 ];
    $self->{langs} = [ qw(Basic C Alg Pascal) ];
    1;
}
1;
