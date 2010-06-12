# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Graph;

use strict;
use warnings;

use List::Util qw(min max);
use EGE::Html;
use EGE::Svg;

sub new {
    my ($class, %init) = @_;
    my $self = { %init };
    bless $self, $class;
    $self;
}

sub edge2 {
    my ($self, $v1, $v2, $w) = @_;
    $self->{edges}->{$v1}->{$v2} = $w;
    $self->{edges}->{$v2}->{$v1} = $w;
}

sub html_matrix {
    my ($self) = @_;
    my @vnames = sort keys %{$self->{vertices}};
    my $r = html->row_n('td', '', @vnames);
    for (@vnames) {
        my $e = $self->{edges}->{$_};
        $r .= html->row_n('td', $_, map $_ || ' ', @$e{@vnames});
    }
    html->table($r, { border => 1 });
}

sub update_min_max {
    my ($value, $min, $max) = @_;
    $$min = $value if !defined($$min) || $value < $$min;
    $$max = $value if !defined($$max) || $value > $$max;
}

sub tagn { html->tag(@_) . "\n" }

sub xy {
    my ($pt, $x, $y) = @_;
    ($x => $pt->[0], $y => $pt->[1]);
}

sub vertex_names { keys %{$_[0]->{vertices}} }

sub edges_string {
    my ($self) = @_;
    my $r = '';
    for my $src (sort $self->vertex_names) {
        my $edges = $self->{edges}{$src};
        my $e = '';
        for my $dest (sort keys %$edges) {
            my $w = $edges->{$dest} or next;
            $e .= "$dest=>$w,";
        }
        $r .= "$src=>{$e}," if $e;
    }
    $r;
}

sub as_svg {
    my ($self) = @_;

    my $radius = 5;
    my $font_size = 3 * $radius;

    my @vnames = $self->vertex_names;
    my @at = map $self->{vertices}{$_}{at}, @vnames;
    my $xmin = min map $_->[0] - $radius, @at;
    my $xmax = max map $_->[0] + $radius + $font_size, @at;
    my $ymin = min map $_->[1] - $radius - $font_size, @at;
    my $ymax = max map $_->[1] + $radius, @at;
    my ($xsize, $ysize) = ();

    
    my @texts;
    my $path = '';
    for my $src (@vnames) {
        my $at = $self->{vertices}{$src}{at};
        push @texts, [ $src, x => $at->[0] + $radius, y => $at->[1] - 3 ];

        my $edges = $self->{edges}{$src};
        for my $e (keys %$edges) {
            my $w = $edges->{$e} or next;
            my $dest_at = $self->{vertices}{$e}{at};
            $path .= "M @$at L @$dest_at ";
            my $c = [ map 0.5 * ($at->[$_] + $dest_at->[$_]), 0 .. 1 ];
            $at->[1] == $dest_at->[1] ?
                $c->[1] -= int($font_size / 2) :
                $c->[0] += 5;
            push @texts, [ $w, xy($c, qw(x y)) ];
        }
    }

    svg->start([ $xmin, $ymin, $xmax - $xmin, $ymax - $ymin ]) .
    svg->g(
        [ map svg->circle(cx => $_->[0], cy => $_->[1], r => $radius), @at ],
        fill => 'black', stroke => 'black', 
    ) .
    svg->path(d => $path, stroke => 'black') .
    svg->g([ map svg->text(@$_), @texts ], 'font-size' => $font_size) .
    svg->end;
}

1;
