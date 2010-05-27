# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A18;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;
use EGE::Svg;

sub row { html->table(html->row('td', @_), { border => 1 }) }

sub gen_labirinth {
    my $s = 5;
    my $lab = [ map [ map 0, 0 .. $s ], 0 .. $s ];
    for (0 .. $s) {
        $lab->[$_][$s] |= 1;
        $lab->[$s][$_] |= 2;
    }
    for (1 .. 10) {
        $lab->[rnd->in_range(0, $s)][rnd->in_range(0, $s)] |= rnd->coin + 1;
    }
    $lab;
}

sub cell_class {
    my ($cell) = @_;
    $cell or return;
    { class => join ' ', ($cell & 1 ? 'b1' : ()), ($cell & 2 ? 'b2' : ()) };
}

# Тег style, вообще говоря, нельзя вставлять внутрь body.
# Поэтому html_labirinth имеет смысл использовать только в отладочных целях.
sub html_labirinth {
    my ($lab) = @_;
    my $r =
        '<style> ' .
        '#A18 { border-collapse: collapse; border: 2px solid black; } ' .
        '#A18 td { width: 20px; height: 20px; border: 1px solid gray; } ' .
        '#A18 .b1 { border-right: 2px solid black } ' .
        '#A18 .b2 { border-bottom: 2px solid black } ' .
        "</style>\n";
    $r .= html->open_tag('table', { id => 'A18' });
    my $mark = sub { '' }; # Для вывода клеток: sub { $_ & 8 ? 'X' : '' };
    for my $lr (@$lab) {
        $r .= html->tr_(
            join '', map html->td($mark->($_), cell_class $_ ), @$lr
        );
    }
    $r . html->close_tag('table');
}

sub svg_labirinth {
    my ($lab) = @_;
    my $step = 25;
    my ($nx, $ny) = (scalar @{$lab->[0]}, scalar @$lab);
    my @sizes = map $_ * $step, $nx, $ny;

    my $r = "\n" . svg->start([ 0, 0, @sizes ]);

    my $mh = sub { my ($x, $y, $l) = map $_ * $step, @_; "M$x,$y h$l" };
    my $mv = sub { my ($x, $y, $l) = map $_ * $step, @_; "M$x,$y v$l" };

    $r .= svg->path(stroke => 'gray', d => join ' ',
        map($mh->(0, $_, $nx), 1 .. $ny - 1),
        map($mv->($_, 0, $ny), 1 .. $nx - 1)
    );

    $r .= html->open_tag('g', { stroke => 'black', 'stroke-width' => 2 });
    $r .= svg->rect(
        x => 1, y => 1, width => $sizes[0] - 2, height => $sizes[1] - 2,
        fill => 'none');
    my @p = ();
    for my $y (0 .. $ny - 1) {
        for my $x (0 .. $nx - 1) {
            my $c = $lab->[$y][$x];
            push @p, $mv->($x + 1, $y, 1) if $x < $nx - 1 && $c & 1;
            push @p, $mh->($x, $y + 1, 1) if $y < $ny - 1 && $c & 2;
        }
    }
    $r .= svg->path(d => join ' ', @p);
    html->div_xy($r . html->close_tag('g') . svg->end, @sizes);
}

sub gen_program {
    my $c1 = rnd->coin;
    my $c2 = rnd->coin;
    my @program = ($c1, $c2, 1 - $c1, 1 - $c2);
    map $program[$_] |= 2, @{ rnd->coin ? [ 0, 2 ] : [ 1, 3 ] };
    \@program;
}

sub test_dir {
    my ($lab, $x, $y, $dir) = @_;
    [
        !$y || $lab->[$y - 1][$x] & 2,
        $lab->[$y][$x] & 2,
        !$x || $lab->[$y][$x - 1] & 1,
        $lab->[$y][$x] & 1,
    ]->[$dir];
};

sub execute_program {
    my ($lab, $program, $x, $y) = @_;
    my @offsets = ([ -1, 0 ], [ 1, 0 ], [ 0, -1 ], [ 0, 1 ]);
    for (@$program) {
        until (test_dir($lab, $x, $y, $_)) {
            $y += $offsets[$_]->[0];
            $x += $offsets[$_]->[1];
        }
    }
    ($x, $y);
}

sub count_loops {
    my ($lab, $program) = @_;
    my $count = 0;
    for my $sy (0 .. $#$lab) {
        for my $sx (0 .. $#{$lab->[$sy]}) {
            my ($x, $y) = execute_program($lab, $program, $sx, $sy);
            next unless $x == $sx && $y == $sy;
            ++$count;
            $lab->[$y][$x] |= 8;
        }
    }
    $count;
}

sub robot_loop {
    my ($self) = @_;
    my @dirs = qw(вверх вниз влево вправо);
    my @tests = map "$_ свободно", qw(сверху снизу слева справа);

    my ($lab, $program, $count);
    do {
        $lab = gen_labirinth;
        $program = gen_program;
        $count = count_loops($lab, $program);
    } while $count < 2;

    my $html_program = join '<br/>',
        'НАЧАЛО',
        map("ПОКА &lt; <b>$tests[$_]</b> > <b>$dirs[$_]</b>", @$program),
        "КОНЕЦ\n";

    $self->{text} =
        '<p>Система команд исполнителя РОБОТ, «живущего» в прямоугольном ' .
        'лабиринте на клетчатой плоскости: ' . row(@dirs) .
        ' При выполнении этих команд РОБОТ перемещается на одну клетку ' .
        'соответственно: вверх ↑, вниз ↓, влево ←, вправо →.</p>' .
        '<p>Четыре команды проверяют условие отсутствия стены у той клетки, ' .
        'где находится РОБОТ ' . row(@tests) .
        '</p><p>Цикл<br/>ПОКА &lt; <i>условие</i> > <i>команда</i> <br/>' .
        'выполняется, пока условие истинно, ' .
        'иначе происходит переход на следующую строку.<br/> ' .
        'Сколько клеток приведённого лабиринта соответствует условию, что, ' .
        'выполнив предложенную ниже программу, ' .
        "РОБОТ остановится в той же клетке, с которой он начал движение?</p>\n" .
        html->table(html->row('td', $html_program, svg_labirinth($lab)));
    my @bad = rnd->pick_n(3, grep $_ > 0 && $_ != $count, $count - 3 .. $count + 3);
    $self->variants($count, @bad);
}

1;
