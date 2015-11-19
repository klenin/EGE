# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A04;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bin;

sub sum {
    my ($self) = @_;
    my $av = rnd->in_range(17, 127);
    my $bv = rnd->in_range(17, 127);
    my $r = $av + $bv;
    my ($atext, $btext) = map hex_or_oct($_), $av, $bv;
    $self->{text} = "Чему равна сумма чисел <i>a</i> = $atext и <i>b</i> = $btext?";
    my @errors = rnd->pick_n(3, map $av ^ (1 << $_), 0..7);
    $self->variants(map bin_hex_or_oct($_, rnd->in_range(0, 2)), $r, @errors);
}

sub bin_to_dec{
	my(@self) = @_;
	my $result;       
	for (my $i = 0; $i <= $#self; $i++){
		$result += $self[$i] * (2 ** $i);	
	}
	return $result;
}

sub zero_one_text {
	my($self, $num) = @_;
	my $res;
	if ($num == 0){$res = $self <= 4 ? 'значащих нуля' : 'значащих нулей'} else
	{$res = $self <= 4 ? 'единицы' : 'единиц'};
	return $res;
}

sub generate_bin {
	my($val, $size, $cur_count) = @_;
	my $back_val = $val == 0 ? 1 : 0;
	
	my @res;
	$res[$size - 1] = 1;
	$cur_count = $val == 1 ? $cur_count - 1 : $cur_count;

	for (my $i = 0; $i < $size - 1; $i++){     
		my $cur_val = rnd->pick(0, 1);
		$res[$i] = ($cur_count != 0) ? $cur_val : $back_val;
		if ($cur_count != 0 && $cur_val == $val) {$cur_count--};
	}          
	
	for (my $i = 0; $i < $size - 1; $i++){    
		if($cur_count != 0 && $res[$i] == $back_val){$res[$i] = $val; $cur_count--;} 
	}
	return @res;
}

sub some_num {
	my ($self) = @_;
	my $z_o = rnd->pick(0, 1);
	my $dgr = rnd->in_range(7, 10);
	my $count = rnd->in_range(2, $dgr - 3);   
	my $type = zero_one_text($count, $z_o);
	my @answ_ar = generate_bin($z_o, $dgr, $count);
	my @error_ar;
	for (my $i = 0; $i < 3; $i++){
		my @error = generate_bin($z_o, $dgr, $count + $i + 1);
		$error_ar[$i] = bin_to_dec(@error); 	 		
	}
	
	my $answ = bin_to_dec(@answ_ar);
                      
	$self->{text} = <<QUESTION
Для каждого из перечисленных ниже десятичных чисел построили
двоичную запись. Укажите число, двоичная запись которого содержит
ровно $count $type.
QUESTION
;       
	$self->variants($answ, @error_ar);
	$self->{correct} = 0;
}
1;
