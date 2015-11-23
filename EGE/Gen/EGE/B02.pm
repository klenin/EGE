# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B02;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Flowchart;
use EGE::LangTable;
use EGE::Bits;

sub flowchart {
    my ($self) = @_;
    my ($va, $vb) = rnd->shuffle('a', 'b');
    my $loop = rnd->pick(qw(while until));
    my ($va_init, $va_end, $va_op, $va_arg, $va_cmp) = rnd->pick(
        sub { 0, rnd->in_range(5, 7), '+', 1, '<' },
        sub { rnd->in_range(5, 7), 0, '-', 1, '>' },
        sub { 1, 2 ** rnd->in_range(3, 5), '*', 2, '<' },
        sub { 2 ** rnd->in_range(3, 5), 1, '/', 2, '>' },
    )->();
    my ($vb_init, $vb_op, $vb_arg) = rnd->pick(
        sub { rnd->in_range(0, 3), rnd->pick('+'), rnd->in_range(1, 3) },
        sub { rnd->in_range(15, 20), rnd->pick('-'), rnd->in_range(1, 3) },
        sub { rnd->in_range(1, 4), '*', rnd->in_range(2, 4) },
        sub { 2 ** rnd->in_range(8, 10), '/', 2 },
    )->();
    my $b = EGE::Prog::make_block([
        '=', $va, $va_init,
        '=', $vb, $vb_init,
        $loop, [ ($loop eq 'while' ? $va_cmp : '=='), $va, $va_end ],
        [
            '=', $va, [ $va_op, $va, $va_arg ],
            '=', $vb, [ $vb_op, $vb, $vb_arg ],
        ],
    ]);
    $self->{text} =
        "Запишите значение переменной $vb после выполнения фрагмента алгоритма:" .
        $b->to_svg_main .
        '<i>Примечание: знаком “:=” обозначена операция присваивания</i>';
    my $vars = { $va => 0, $vb => 0 };
    $b->run($vars);
    $self->{correct} = $vars->{$vb};
    $self->{accept} = qr/^\-?\d+/;
}

sub simple_while {
    my ($self) = @_;
    my $lo = rnd->in_range(0, 5);
    my $hi = $lo + rnd->in_range(3, 5);
    my $p = rnd->coin ?
        { op => '+', start => $lo, end => $hi, comp => [ '<', '<=' ] } :
        { op => '-', start => $hi, end => $lo, comp => [ '>', '>=' ] };
    my $block = EGE::Prog::make_block([
        '=', 's', rnd->in_range(1, 10),
        '=', 'k', $p->{start},
        'while', [ rnd->pick(@{$p->{comp}}), 'k', $p->{end} ], [
            '=', 's', [ '+', 's', 'k' ],
            '=', 'k', [ $p->{op}, 'k', 1 ],
        ],
    ]);
    $self->{text} =
        'Напишите, чему равно значение переменной <tt>s</tt> после выполнения следующего блока программы. ' .
        'Для вашего удобства алгоритм представлен на четырех языках. ' .
        EGE::LangTable::table($block, [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C' ] ]);
    $self->{correct} = $block->run_val('s');
}

1;
