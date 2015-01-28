# Copyright © 2010-2011 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::Complexity;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::LangTable;

use constant MAX_DEGREE => 5;

sub pow {
    my ($var, $degree) = @_;
    if ($degree > 1) {
        ['*', $var, pow($var, --$degree)]
    }
    elsif ($degree == 1) {
        $var
    }
    else {
        rnd->const_value
    }
}

sub to_logic { EGE::Prog::make_expr($_[0])->to_lang_named('Logic') }
sub big_o { "<i>O</i>($_[0])" }

sub cycle_complexity
{
    my ($self) = @_;    
    my $main_var = rnd->pick(qw(N M K));
    
    my @vars = rnd->index_var(3);
    $self->{correct} = 0;
    my @degrees = rnd->shuffle(1..MAX_DEGREE);
    @degrees = @degrees[1..3];
    my $cycles = [
        'for', $vars[0], 0, pow($main_var, $degrees[0]), [
            'for', $vars[1], 0, pow($main_var, $degrees[1]), [ 
                '=', ['[]', 'buf', $vars[1]], $vars[1]
            ],
            'for', $vars[2], 0, pow($main_var, $degrees[2]), [ 
                '=', ['[]', 'buf', $vars[2]], $vars[2]
            ]
        ]
    ];
    my $block = EGE::Prog::make_block($cycles);
    my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
    $self->{text} = "Асимптотическая сложность следующего алгоритма равна: $lt";
    my @variatns = ($block->complexity({$main_var => 1}), 
        $degrees[0] + List::Util::min(@degrees[1..2]), 
        $degrees[1] + $degrees[2],
        $degrees[0]);
    $self->variants(map big_o(to_logic(['**', $main_var, $_])), @variatns);
}
1;
