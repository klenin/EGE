# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A17;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use List::Util qw(max sum);
use POSIX qw(ceil);

use EGE::Random;
use EGE::Russian::Subjects;
use EGE::Html;
use EGE::Svg;

sub regions() {qw(
    Адыгея
    Башкортостан
    Бурятия
    Алтай
    Дагестан
    Ингушетия
    Калмыкия
    Карелия
    Коми
    Мордовия
    Якутия
    Осетия
    Татарстан
    Удмуртия
    Хакасия
    Чувашия
)}

my @colors = qw(red green blue);

use constant SZ => 350;
use constant STEP => 10;
use constant LEFT_MARKS => 50;
use constant LEGEND => 200;

sub text {
    my ($labels, $anchor, $baseline) = @_;
    $labels =~ s/\n//g;
    svg->text($labels, 'text-anchor' => $anchor, 'dominant-baseline' => $baseline);
}

sub bar_chart {
    my ($data, $labels1, $labels2) = @_;

    my $max_y = STEP / 2 + max map max(@$_), @$data;
    my @sizes = (SZ + LEFT_MARKS + LEGEND + 10, SZ + 20);
    my $r = svg->start([ 0, 0, @sizes ]);

    my $grid_path = '';
    my $y_labels = '';
    for (my $i = 0; $i < $max_y; $i += STEP) {
        my $y = int((1 - $i / $max_y) * SZ);
        $y_labels .= svg->tspan($i, x => LEFT_MARKS - 5, y => $y);
        $grid_path .= ' M' . LEFT_MARKS . ",$y h" . SZ;
    }
    $r .= text($y_labels, 'end', 'middle');

    $r .= html->open_tag('g', { stroke => 'black' });
    $r .= svg->rect(x => LEFT_MARKS, width => SZ, height => SZ, fill => 'none');
    $r .= svg->path(d => $grid_path, 'stroke-dasharray' => '3,3');

    my $total_data = @$data * (@{$data->[0]} + 1) + 1;
    my $pos = 0;
    my $color = 0;
    my @paths = (
        'M0,0 L10,10 M0,-10 L20,10 M-10,0 L10,20',
        'M0,10 L10,0 M-10,10 L10,-10 M20,0 L0,20',
        'M0,0 L10,10 M10,0 L0,10');
    my $step = SZ / $total_data;
    for my $row (@$data) {
        for (@$row) {
            my $y = ceil($_ / $max_y * SZ);
            $r .= svg->pattern(
                svg->path(
                    d => $paths[$color / @paths],
                    stroke => $colors[$color % @colors],
                    'stroke-width' => 2,
                ),
                patternUnits => 'userSpaceOnUse',
                id => "p$color", viewBox => '0 0 10 10',
                width => STEP / 2, height => STEP / 2);
            $r .= svg->rect('stroke-width' => 2,
                x => LEFT_MARKS + ceil(++$pos * $step), y => SZ - $y,
                width => ceil($step), height => $y,
                fill => "url(#p$color)");
            ++$color;
        }
        ++$pos;
    }

    $r .= svg->rect(
        x => LEFT_MARKS + SZ + 10,
        width => LEGEND, height => 5 + 25 * @$labels2, fill => 'none');
    $pos = 0;
    $y_labels = '';
    for (@$labels2) {
        $r .= svg->rect(
            x => LEFT_MARKS + SZ + 15, y => 5 + 25 * $pos,
            width => 20, height => 20, fill => $colors[$pos]);
        $y_labels .= svg->tspan($_, x => LEFT_MARKS + SZ + 40, y => 15 + 25 * $pos);
        ++$pos;
    }
    $r .= html->close_tag('g');
    $r .= text($y_labels, 'start', 'middle');

    $pos = 1;
    my $x_labels = '';
    my $i = 0;
    for (@$labels1) {
        my $d = @{$data->[$i]};
        $x_labels .= svg->tspan(
            $_, x => LEFT_MARKS + ceil(($pos + $d / 2) * $step), y => SZ + 1);
        $pos += $d + 1;
        ++$i;
    }
    $r .= text($x_labels, 'middle', 'text-before-edge');

    div_xy($r . svg->end, @sizes);
}

sub div_xy {
    my ($text, $x, $y) = @_;
    html->div($text, { html->style(width => "${x}px", height => "${y}px") });
}

use constant PIE_SZ => 60;
use constant PI => 3.141592653589793238;

sub pie_chart {
    my ($data) = @_;
    my $r = svg->start([ 0, 0, PIE_SZ, PIE_SZ ]).
        html->open_tag('g', { stroke => 'black' });
    my $radius = PIE_SZ / 2 - 5;
    my ($cx, $cy) = (PIE_SZ / 2, PIE_SZ / 2);
    my ($prev_x, $prev_y, $angle) = ($cx + $radius, $cy, 0);
    my $total = sum @$data;
    my $color = 0;
    for (@$data) {
        my $large_arc = 2 * $_ >= $total ? 1 : 0;
        $angle += $_ / $total * 2 * PI;
        my $x = sprintf '%.5f', $radius * cos($angle) + $cx;
        my $y = sprintf '%.5f', $radius * sin($angle) + $cy;
        $r.= svg->path(
            d=> "M$cx,$cy L$prev_x,$prev_y A$radius,$radius 0 $large_arc,1 $x,$y Z ",
            fill => $colors[$color++]);
        $prev_x = $x;
        $prev_y = $y;
    }
    div_xy($r . html->close_tag('g') . svg->end, PIE_SZ * 2, PIE_SZ * 2);
}

sub diagram {
    my ($self) = @_;
    my @regions = rnd->pick_n(3, regions());
    my @subjects = rnd->pick_n(3, @EGE::Russian::Subjects::list);
    my @splits = ([ 2, 1, 1 ], [ 1, 1, 1 ], [ 2, 2, 1 ], [ 3, 2, 1 ]);
    $self->{correct} = rnd->in_range(0, $#splits);
    my $k = rnd->in_range(10, 20);
    my $data;
    for my $c (0 .. 2) {
        my @s = rnd->split_number($k * $splits[$self->{correct}]->[$c], 3);
        $data->[$_]->[$c] = $s[$_] * STEP for 0 .. 2;
    }
    my $chart = bar_chart($data, \@regions, \@subjects);
    $self->{text} =
        'На диаграмме показано количество участников олимпиады ' .
        "по трём предметам в трёх регионах России $chart " .
        'Какая из диаграмм правильно отражает соотношение участников ' .
        'из всех регионов по каждому предмету?';
    $self->variants(map pie_chart($_), @splits);
}

1;
