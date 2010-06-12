# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
use strict;
use warnings;
use utf8;

package EGE::Prog::Flowchart;

use List::Util qw(min max);
use EGE::Prog::Lang;
use EGE::Html;
use EGE::Svg;

use constant FONT_SZ => 15;

sub new {
    my ($class, %init) = @_;
    my $self = {
        x => 0, y => 0, x1 => 0, y1 => 0, x2 => 0, y2 => 0,
        texts => {}, jumps => [],
        %init
    };
    bless $self, $class;
    $self;
}

sub add_text {
    my ($self, $anchor, @rest) = @_;
    push @{$self->{texts}->{$anchor}}, \@rest;
}

sub make_jump {
    my ($self, $init) = @_;
    $init ||= {};
    push @{$self->{jumps}}, $init;
    $init;
}

sub down { $_[0]->{y2} += $_[1] || 30; }

sub point {
    my ($self, $x, $y) = @_;
    { x => (defined $x ? $x : 0), y => (defined $y ? $y : $self->{y2}) }
}

sub add_box {
    my ($self, $statements, $enter, $exit) = @_;
    my $w = max(map length, @$statements) * FONT_SZ;
    $self->{x1} = min($self->{x1}, -$w / 2);
    $self->{x2} = max($self->{x2}, $w / 2);
    my $y = $self->{y2} + FONT_SZ;
    for (@$statements) {
        $self->add_text(middle => $_, x => 0, y => $y);
        $y += FONT_SZ;
    }
    my $r .= svg->rect(
        x => -$w / 2, y => $self->{y2},
        width => $w, height => $y - $self->{y2});
    $enter->{dest} = $self->point if $enter;
    $self->{y2} = $y;
    $exit->{src} = $self->point if $exit;
    $r;
}

sub add_rhomb {
    my ($self, $cond, $enter, $exits) = @_;
    my $w = length($cond) * FONT_SZ;
    $self->{x1} = min($self->{x1}, -$w);
    $self->{x2} = max($self->{x2}, $w);
    my $fs = FONT_SZ * 2;
    $enter->{dest} = $self->point if $enter;
    my $r = svg->path(d => "M0,$self->{y2} l-$w,$fs l$w,$fs l$w,-$fs z");
    $self->add_text(middle => $cond, x => 0, y => $self->{y2} + $fs);
    my $add_exit = sub {
        my ($exit, $x, $dy) = @_;
        $exits->{$exit}->{src} = { x => $x, y => $self->{y2} + $dy }
            if $exits->{$exit};
    };
    $add_exit->('left', -$w, $fs);
    $add_exit->('right', $w, $fs);
    $add_exit->('middle', 0, 2 * $fs);
    $self->down($fs * 2);
    $r;
}

sub quote_tspan {
    $_[0] = html->cdata($_[0]) if $_[0] =~ /[<&]/;
    svg->tspan(@_);
}

sub texts {
    my ($self) = @_;
    my $r = '';
    for my $anchor (keys %{$self->{texts}}) {
        my $t = $self->{texts}->{$anchor};
        $r .= svg->text(
            "\n" . join('', map quote_tspan(@$_), @$t),
            'font-size' => FONT_SZ, 'text-anchor' => $anchor,
            'dominant-baseline' => 'middle');
    }
    $r;
}

sub arrow_head {
    my ($dir) = @_;
    my ($AL, $AW) = (10, 5);
    my ($dx, $dy, $v) = @{{
        right => [ -$AL, $AW ], up => [ $AW, $AL, 1 ],
        left => [ $AL, $AW ], down => [ $AW, -$AL, 1 ],
    }->{$dir}};
    my ($ndx, $ndy) = (-$dx, -$dy);
    "l$dx,$dy m$ndx,$ndy l" . ($v ? "$ndx,$dy " : "$dx,$ndy ");
}

sub jumps {
    my ($self, $name) = @_;
    my $p = '';
    for my $j (@{$self->{jumps}}) {
        my ($sx, $sy) = @{$j->{src}}{qw(x y)};
        my ($dx, $dy) = @{$j->{dest}}{qw(x y)};
        my $label = $j->{label} || '';
        $p .= "M$sx,$sy ";
        if ($sx == 0 && !$j->{dir}) {
            $self->add_text(
                start => $label, x => $sx + FONT_SZ / 2, y => $sy + FONT_SZ / 2
            ) if $label;
            $p .= "V$dy " . arrow_head('down');
            next;
        }
        my $right = ($j->{dir} || '') eq 'right' || $sx > 0;
        my $dist = max(1, length $label) * FONT_SZ;
        my $x = $right ? ($self->{x2} += $dist) : ($self->{x1} -= $dist);
        $self->add_text(
            ($right ? 'start' : 'end') => $label,
            x => $sx, y => $sy - FONT_SZ / 2
        ) if $label;
        my $ah = arrow_head($dy > $sy ? 'down' : $right ? 'left' : 'right');
        if ($dy > $sy) {
            $dy -= 20;
            $ah = "v20 $ah";
        }
        else {
            $p .= 'v10 ';
        }
        $p .= "H$x V$dy H$dx $ah";
    }
    svg->path(d => $p);
}

package EGE::Prog::CondLoop;

sub to_svg {
    my ($self, $f, $enter, $exit) = @_;
    my $top = $f->make_jump({ dest => $f->point, dir => 'left' });
    $f->down(20);
    my $middle = $f->make_jump({ label => $self->continue_label });
    $exit->{label} = $self->exit_label;
    my $r =
        $f->add_rhomb(
            $self->{cond}->to_lang_named('Alg'),
            $enter, { right => $exit, middle => $middle });
    $f->down;
    $r .= $self->{body}->to_svg($f, $middle, $top);
    $f->down(10);
    $r;
}

package EGE::Prog::While;

sub continue_label { 'Да' }
sub exit_label { 'Нет' }

package EGE::Prog::Until;

sub continue_label { 'Нет' }
sub exit_label { 'Да' }

package EGE::Prog::Block;

use EGE::Html;
use EGE::Svg;

sub to_svg {
    my ($self, $f, $enter, $exit) = @_;
    my $r = '';

    my @elements;
    my $linear = [];
    for (@{$self->{statements}}, undef) {
        if ($_ && $_->isa('EGE::Prog::Assign')) {
            push @$linear, $_->to_lang_named('Alg');
        }
        else {
            push @elements, $linear if @$linear;
            $linear = [];
            push @elements, $_ if $_;
        }
    }

    my $j;
    for (@elements) {
        $j = $_ eq $elements[-1] ? $exit : $f->make_jump;
        if (ref $_ eq 'ARRAY') {
            $r .= $f->add_box($_, $enter, $j);
            $f->down;
        }
        else {
            $r .= $_->to_svg($f, $enter, $j);
        }
        $enter = $j;
    }
    $r;
}

sub to_svg_main {
    my ($self) = @_;
    my $f = EGE::Prog::Flowchart->new(x => 0, y => 0);
    my $exit = $f->make_jump;
    my $r = $self->to_svg($f, undef, $exit);
    $exit->{dest} = $f->point;
    $r = svg->g("\n$r" . $f->jumps, stroke => 'black', fill => 'none') . $f->texts;
    $f->{y2} += 1;
    $f->{x2} += 1;
    my @wh = ($f->{x2} - $f->{x1}, $f->{y2} - $f->{y1});
    html->div_xy(
        "\n" . svg->start([ @$f{qw(x1 y1)}, @wh ]) . $r . svg->end, @wh);
}

1;
