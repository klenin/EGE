# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
use strict;
use warnings;

package EGE::Prog::Flowchart;

use List::Util qw(min max);
use EGE::Prog::Lang;
use EGE::Svg;

use constant FONT_SZ => 15;

sub new {
    my ($class, %init) = @_;
    my $self = {
        x => 0, y => 0, x1 => 0, y1 => 0, x2 => 0, y2 => 0,
        texts => [], jumps => [],
        %init
    };
    bless $self, $class;
    $self;
}

sub add_text {
    my $self = shift;
    push @{$self->{texts}}, [ @_ ];
}

sub add_jump {
    my $self = shift;
    push @{$self->{jumps}}, @_;
}

sub add_arrow {
    my ($self, $dy) = @_;
    my $r = svg->path(
        d => "M$self->{x},$self->{y2} v$dy l5,-10 m-5,10 l-5,-10");
    $self->{y2} += $dy;
    $r;
}

sub add_box {
    my ($self, $statements) = @_;
    my $w = max(map length($_), @$statements) * FONT_SZ;
    $self->{x1} = min($self->{x1}, -$w / 2);
    $self->{x2} = max($self->{x2}, $w / 2);
    my $y = $self->{y2} + FONT_SZ;
    for (@$statements) {
        $self->add_text($_, x => 0, y => $y);
        $y += FONT_SZ;
    }
    my $r .= svg->rect(
        x => -$w / 2, y => $self->{y2},
        width => $w, height => $y - $self->{y2});
    $self->{y2} = $y; 
    $r;
}

sub add_rhomb {
    my ($self, $cond, %exits) = @_;
    my $w = length($cond) * FONT_SZ;
    $self->{x1} = min($self->{x1}, -$w);
    $self->{x2} = max($self->{x2}, $w);
    my $fs = FONT_SZ * 2;
    my $r =
        $self->add_arrow(30) .
        svg->path(d => "M0,$self->{y2} l-$w,$fs l$w,$fs l$w,-$fs z") .
        $self->add_text($cond, x => 0, y => $self->{y2} + $fs);
    $exits{left}->{src} = { x => -$w, y => $self->{y2} + $fs }
        if $exits{left};
    $exits{right}->{src} = { x => $w, y => $self->{y2} + $fs }
        if $exits{right};
    $exits{middle}->{src} = { x => 0, y => $self->{y2} + 2 * $fs }
        if $exits{middle};
    $self->{y2} += $fs * 2;
    $r;
}

sub texts {
    my ($self) = @_;
    svg->text(
        join("\n", map svg->tspan(@$_), @{$self->{texts}}),
        'font-size' => FONT_SZ, 'text-anchor' => 'middle',
        'dominant-baseline' => 'middle');
}

sub jumps {
    my ($self, $name) = @_;
    my $p = '';
    for my $j (@{$self->{jumps}}) {
        my ($sx, $sy) = @{$j->{src}}{qw(x y)};
        $p .= "M$sx,$sy ";
        if ($sx == 0) {
            $p .= 'v10 '
        }
        if ($sx > 0 || $j->{right}) {
            $p .= "h200 V$j->{dest}->{y} H$j->{dest}->{x} ";
        }
        elsif ($sx < 0 || $j->{left}) {
            $p .= "h-200 V$j->{dest}->{y} H$j->{dest}->{x} ";
        }
    }
    svg->path(d => $p);
}

package EGE::Prog::While;

use EGE::Svg;

sub to_svg {
    my ($self, $f) = @_;
    my $top = { dest => { x => 0, y => $f->{y2} } };
    my $r = $f->add_arrow(30);
    my $right = {};
    $r .=
        $f->add_rhomb($self->{cond}->to_lang_named('Alg'), right => $right) .
        $self->{body}->to_svg($f);
    $top->{src} = { x => 0, y => $f->{y2}, left => 1 };
    $self->{y2} += 20;
    $right->{dest} = { x => 0, y => $f->{y2} };
    $f->add_jump($top, $right);
    $r;
}

package EGE::Prog::Block;

use EGE::Html;
use EGE::Svg;

sub to_svg {
    my ($self, $f, $no_arrow) = @_;
    my $r = '';
    my $linear = [];
    for (@{$self->{statements}}, undef) {
        if ($_ && $_->isa('EGE::Prog::Assign')) {
            push @$linear, $_->to_lang_named('Alg');
        }
        else {
            $r .= $f->add_arrow(30) unless $no_arrow;
            $no_arrow = 0;
            $r .= $f->add_box($linear) if @$linear;
            $linear = [];
            $r .= $_->to_svg($f) if $_;
        }
    }
    $r;
}

sub to_svg_main {
    my ($self) = @_;
    my $f = EGE::Prog::Flowchart->new(x => 0, y => 0);
    my $r =
        svg->g($self->to_svg($f, 1) . $f->jumps, stroke => 'black', fill => 'none') .
        $f->texts;
    $f->{y2} += 1;
    $f->{x2} += 1;
    my @wh = ($f->{x2} - $f->{x1}, $f->{y2} - $f->{y1});
    html->div_xy(
        "\n" . svg->start([ @$f{qw(x1 y1)}, @wh ]) . $r . svg->end, @wh);
}

1;
