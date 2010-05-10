package EGE::Gen::A10;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Graph;

sub svg_in_box {
    my $svg = $_[0]->svg;
    qq~<div style="width: 120px; height: 80px; margin: 5px;">\n$svg\n</div>~;
}

sub graph_by_matrix {
    my %vertices = (
        'A' => { at => [  50,  0 ] },
        'B' => { at => [  25, 50 ] },
        'C' => { at => [  75, 50 ] },
        'D' => { at => [   0,  0 ] },
        'E' => { at => [ 100,  0 ] },
    );
    my @edges = (
         [ qw(A B) ], [ qw(A C) ], [ qw(A D) ], [ qw(A E) ], 
         [ qw(B C) ], [ qw(B D) ],
         [ qw(C E) ],
    );
    # TODO: генерировать связные графы, генерировать незначительные отклонения
    my $make_random_graph = sub {
        my $g = EGE::Graph->new(vertices => \%vertices);
        $g->edge2(@$_, rnd->in_range(2, 5)) for rnd->pick_n(5, @edges);
        $g;
    };

    my $g = $make_random_graph->();
    my @bad;
    my %seen = ($g->edges_string => 1);
    while (@bad < 3) {
        my $g1;
        do { $g1 = $make_random_graph->() } while $seen{$g1->edges_string}++;
        push @bad, $g1;
    }
    {
        question =>
            'В таблице приведена стоимость перевозки между ' .
            'соседними железнодорожными станциями. ' .
            'Укажите схему, соответствующую таблице: ' . $g->html_matrix,
        variants => [ map svg_in_box($_), $g, @bad ],
        answer => 0,
    };
}

1;
