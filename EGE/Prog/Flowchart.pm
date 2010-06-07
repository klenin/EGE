# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Prog::Flowchart;

use strict;
use warnings;

use List::Util qw(min max);
use EGE::Prog::Lang;
use EGE::Svg;

sub new {
    my ($class, %init) = @_;
    my $self = { x => 0, y => 0, x1 => 0, y1 => 0, x2 => 0, y2 => 0, %init };
    bless $self, $class;
    $self;
}

sub add_arrow {
    my ($self, $dy) = @_;
    my $r = svg->path(
        d => "M$self->{x},$self->{y} v$dy l5,-10 m-5,10 l-5,-10",
        stroke => 'black', fill => 'none');
    $self->{y} += $dy;
    $r;
}

sub add_box {
    my ($self, $statements) = @_;
    my $r = $self->add_arrow(30);
    my $h = @$statements * 20 + 20;
    my $w = max(map length($_), @$statements) * 10;
    $self->{x1} = min($self->{x1}, -$w / 2);
    $self->{x2} = max($self->{x2}, $w / 2);
    $r .= svg->rect(
        x => -$w / 2, y => $self->{y},
        width => $w, height => $h, stroke => 'black', fill => 'none');
    my $y = $self->{y} + 10;
    for (@$statements) {
        $r .= svg->text($_, x => -$w / 2 + 10, y => $y);
        $y += 20;
    }
    $self->{y} += $h; 
    $r;
}

sub as_svg {
    my ($self) = @_;
}

package EGE::Prog::Block;

use EGE::Html;
use EGE::Svg;

sub as_svg {
    my ($self) = @_;
    my $f = EGE::Prog::Flowchart->new(x => 0, y => 0);
    my $str = [ split /\n/, $self->to_lang_named('Alg') ];
    my $r = $f->add_box($str);
    $f->{y2} = $f->{y} + 1;
    $f->{x2} += 1;
    my @wh = ($f->{x2} - $f->{x1}, $f->{y2} - $f->{y1});
    html->div_xy(
        "\n" . svg->start([ @$f{qw(x1 y1)}, @wh ]) . $r . svg->end, @wh
    );
}

1;
