# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A10;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Graph;
use EGE::Html;
use EGE::Random;

sub graph_by_matrix {
    my ($self) = @_;
    my %vertices = (
        A => { at => [  50,  0 ] },
        B => { at => [  25, 50 ] },
        C => { at => [  75, 50 ] },
        D => { at => [   0,  0 ] },
        E => { at => [ 100,  0 ] },
    );
    my @edges = (
         [ qw(A B) ], [ qw(A C) ], [ qw(A D) ], [ qw(A E) ], 
         [ qw(B C) ], [ qw(B D) ],
         [ qw(C E) ],
    );
    # TODO: генерировать незначительные отклонения
    my $make_random_graph = sub {
        while (1) {
            my $g = EGE::Graph->new(vertices => \%vertices);
            $g->edge2(@$_, rnd->in_range(2, 5)) for rnd->pick_n(5, @edges);
            return $g if $g->is_connected;
        }
    };

    my $g = $make_random_graph->();
    my @bad;
    my %seen = ($g->edges_string => 1);
    while (@bad < 3) {
        my $g1;
        do { $g1 = $make_random_graph->() } while $seen{$g1->edges_string}++;
        push @bad, $g1;
    }
    $self->{text} =
        'В таблице приведена стоимость перевозки между ' .
        'соседними железнодорожными станциями. ' .
        'Укажите схему, соответствующую таблице: ' . $g->html_matrix;
    $self->variants(map html->div_xy($_->as_svg, 120, 80, { margin => '5px' }), $g, @bad);
}

sub light_panel {
    my ($self) = @_;
    my $n = rnd->in_range(10, 20);
    my $first = $n  - rnd->in_range(4, 16);
    my $last = $n - $first;
    $self->{text} = <<QUESTION
На световой панели в ряд расположены $n лампочек. Каждая из первых $first лампочек может гореть красным, жёлтым или зелёным цветом. 
Каждая из остальных $last лампочек может гореть одним из двух цветов - красным или белым.
Сколько различных сигналов можно передать с помощью панели (все лампочки должны гореть, порядок цветов имеет значение)?
QUESTION
;
    $self->variants((3**$first) * (2**$last), (3**$first) + (2**$last), ($first**3) * ($last**2), ($first**3) + ($last**2));
}

1;
