package EGE::Graph;

use strict;
use warnings;

use List::Util qw(min max);
use EGE::Html;

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

sub svg {
    my ($self) = @_;

    my $radius = 5;
    my $font_size = 3 * $radius;

    my @vnames = $self->vertex_names;
    my @at = map $self->{vertices}{$_}{at}, @vnames;
    my $xmin = min map $_->[0] - $radius, @at;
    my $xmax = max map $_->[0] + $radius + $font_size, @at;
    my $ymin = min map $_->[1] - $radius - $font_size, @at;
    my $ymax = max map $_->[1] + $radius, @at;
    my ($xsize, $ysize) = ($xmax - $xmin, $ymax - $ymin);

    my $r =
        '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" ' .
        qq~viewBox="$xmin $ymin $xsize $ysize" ~ .
        'preserveAspectRatio="meet"> '.
        qq~<g fill="black" stroke="black" font-size="$font_size">\n~;
    $r .= tagn('circle', undef, { xy($_, qw(cx cy)), r => $radius }) for @at;
    for my $src (@vnames) {
        my $at = $self->{vertices}{$src}{at};
        $r .= tagn('text', " $src", { xy($at, qw(x y)), dx => $radius, dy => -3 });
        my %xy1 = xy($at, qw(x1 y1));

        my $edges = $self->{edges}{$src};
        for my $e (keys %$edges) {
            my $w = $edges->{$e} or next;
            my $dest_at = $self->{vertices}{$e}{at};
            $r .= tagn('line', undef, { %xy1, xy($dest_at, qw(x2 y2)) });
            my $c = [ map 0.5 * ($at->[$_] + $dest_at->[$_]), 0 .. 1 ];
            $at->[1] == $dest_at->[1] ? $c->[1] -= $font_size / 2 : $c->[0] += 5;
            $r .= tagn('text', " $w", { xy($c, qw(x y)) });
        }
    }
    $r . '</g></svg>';
}

1;
