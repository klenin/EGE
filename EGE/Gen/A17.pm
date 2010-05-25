# Copyright  2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A17;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use List::Util qw(max);

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

use constant SZ => 350;

sub bar_chart {
    my ($data) = @_;

    my $max_y = 50 + max map max(@$_), @$data;
    my $r = svg->start([0, 0, SZ, SZ + 1]);
    for (my $i = 0; $i < $max_y; $i += 50) {
        my $y = int((1 - $i / $max_y) * SZ);
        $r .= svg->text($i, x => 0, y => $y);
    }

    $r .= html->open_tag('g', { stroke => 'black' });

    $r .= svg->rect(width => SZ, height => SZ, fill => 'none');
    my $p = '';
    for (my $i = 0; $i < $max_y; $i += 50) {
        my $y = int((1 - $i / $max_y) * SZ);
        $p .= " M 0 $y H " . SZ;
    }
    $r .= svg->path(d => $p, 'stroke-dasharray' => '3,3');

    my $total_data = @$data * (@{$data->[0]} + 1) + 1;
    my $pos = 0;
    my $color = 0;
    my @colors = qw(red green blue);
    my @paths = (
        'M 0 0 L 10 10 M 0 5 L 5 10 M 5 0 L 10 5',
        'M 10 0 L 0 10 M 0 5 L 5 0 M 5 10 L 10 5',
    );
    push @paths, join ' ', @paths;
    my $step = sprintf '%.2f', SZ / $total_data;
    for my $row (@$data) {
        for (@$row) {
            my $y = sprintf '%.2f', $_ * SZ / $max_y;
            $r .= svg->pattern(
                svg->path(
                    d => $paths[$color / 3],
                    stroke => $colors[$color % 3],
                    'stroke-width' => '2',
                ),
                patternUnits => 'userSpaceOnUse',
                id => "p$color", viewBox => '0 0 10 10', width => 50, height => 50);
            $r .= svg->rect(
                x => ++$pos * $step, y => SZ - $y, width => $step, height => $y,
                fill => "url(#p$color)");
            ++$color;
        }
        ++$pos;
    }

    $r . html->close_tag('g') . svg->end;
}

sub diagram {
    my ($self) = @_;
    my @regions = rnd->pick_n(3, regions());
    my @subjects = rnd->pick_n(3, @EGE::Russian::Subjects::list);
    my $data;
    for my $r (0 .. 2) {
        $data->[$r] = [ map rnd->in_range(1, 9) * 50, 0 .. 2 ];
    }
    $self->{text} = html->div(
        bar_chart($data),
        { html->style(width => SZ . 'px', height => SZ . 'px') });
    $self->variants(1, 2, 3);
}

1;
