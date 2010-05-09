package EGE::Graph;

use strict;
use warnings;

use List::Util qw(min max);

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

sub html_row {
    my $r = join '', map "<td>$_</td>", map $_ || ' ', @_;
    "<tr>$r</tr>\n";
}

sub html_matrix {
    my ($self) = @_;
    my @vnames = sort keys %{$self->{vertices}};
    my $r = html_row(undef, @vnames);
    for (@vnames) {
        my $e = $self->{edges}->{$_};
        $r .= html_row($_, @$e{@vnames});
    }
    qq~<table border="1">$r</table>~;
}

sub update_min_max {
    my ($value, $min, $max) = @_;
    $$min = $value if !defined($$min) || $value < $$min;
    $$max = $value if !defined($$max) || $value > $$max;
}

sub tag {
    my ($tag, $attrs, $body) = @_;
    "<$tag" . join('', map qq~ $_="$attrs->{$_}"~, keys %$attrs) .
    ($body ? ">$body</$tag>" : '/>');
}

sub tagn { tag(@_) . "\n" }

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
    $r .= tagn('circle', { xy($_, qw(cx cy)), r => $radius }) for @at;
    for my $src (@vnames) {
        my $at = $self->{vertices}{$src}{at};
        $r .= tagn('text', { xy($at, qw(x y)), dx => $radius, dy => -3 }, " $src");
        my %xy1 = xy($at, qw(x1 y1));

        my $edges = $self->{edges}{$src};
        for my $e (keys %$edges) {
            my $w = $edges->{$e} or next;
            my $dest_at = $self->{vertices}{$e}{at};
            $r .= tagn('line', { %xy1, xy($dest_at, qw(x2 y2)) });
            my $c = [ map 0.5 * ($at->[$_] + $dest_at->[$_]), 0 .. 1 ];
            $at->[1] == $dest_at->[1] ? $c->[1] -= $font_size / 2 : $c->[0] += 5;
            $r .= tagn('text', { xy($c, qw(x y)) }, " $w");
        }
    }
    $r . '</g></svg>';
}

1;
