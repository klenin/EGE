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

sub simple_while{
	my ($self) = @_;
	my $s_v = rnd->in_range(0, 25);
	my $k_v = rnd->in_range(4, 8);
	my $i = rnd->in_range(0, 12);
	my $dg = rnd->in_range(4, 6);
	my $oprtn;
	my $cmprt;
	if ($k_v >= $i){
		$oprtn = '-';
		$cmprt = rnd->pick('>', '>=');  #
		my $sbt = $k_v - $i;
		$i = $sbt < 4 ? $k_v - $dg - rnd->in_range(0, $i) : $i;
	}   
	else{   
		$oprtn = '+';
		$cmprt = rnd->pick('<', '<='); #                                
		my $sbt = $i - $k_v;
		$i = $sbt < 4 ? $k_v + $dg + rnd->in_range(0, $i) : $i;
	}
	my $block = EGE::Prog::make_block([
        	'=', 's', \$s_v,
		'=', 'k', \$k_v,
		'while', [ $cmprt, 'k', $i ], [
			'=', 's', [ '+', 's', 'k' ],
			'=', 'k', [ $oprtn, 'k', 1 ],
		],
	]);
	my $lt = EGE::LangTable::table($block, [ [ 'Basic', 'Alg' ], [ 'Pascal', 'C' ] ]);
	$self->{text} = <<QUESTION
Напишите чему равно значение переменной s после выполнения следующего блока программы.
Для вашего удобства алгоритм представлен на четырех языках.
$lt
QUESTION
;

	$self->{correct} = $block->run_val('s');
	
}
1;
