# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::RandComplexity;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use List::Util;

use EGE::Prog;
use EGE::Random;
use EGE::Alg;

sub rand_complexity
{
    my ($self) = @_;
    my $main_var = rnd->pick(qw(n m));
    my $max_counts = {
        if => 4,
        assign => 4,
        rand => 3
    };
    my $for_count = rnd->in_range(4, 6);
    my $vars = { all => { $main_var => 1 }, iterator => {}, if => {} };
    my $cycle = [ EGE::Alg::make_rnd_block($for_count, $max_counts, $vars) ];
    my $block = EGE::Prog::make_block($cycle);
    my $rand_case = rnd->pick(qw(average worth best));
    $self->{correct} = $block->complexity({ $main_var => 1 }, {}, {}, $rand_case);
    my $lt = EGE::LangTable::table($block, [ [ 'C', 'Basic' ], [ 'Pascal', 'Alg', 'Perl' ] ]);
    my $to_russian = { average => 'среднем', worth => 'худшем', best => 'лучшем' };
    $self->{text} = "Сложность представленного ниже алгоритма в <i>$to_russian->{$rand_case}</i> случае равна " .
        EGE::Alg::big_o(EGE::Alg::to_logic([ '**', $main_var, 'X' ])) . ". Чему равно <i>X</i>?" .
        " <br/> <i>Прим.</i> Функция rand(a,b) возвращает случайное целочисленное значение из отрезка [a,b].$lt";
}

1;
