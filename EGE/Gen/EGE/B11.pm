# Copyright © 2010-2014 Alexander S. Klenin
# Copyright © 2012 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B11;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;

sub _bits_to_mask {
    map oct("0b$_"), unpack 'a8' x 4, (1 x $_[0] . 0 x (32 - $_[0]))
}

sub _prepare {
    my ($header, $parts, $ip) = @_;
    my $find_part = sub { (grep $parts->[$_] == $_[0], 0 .. $#$parts)[0] };
    (
        join('', map $header->[$find_part->($_)], @$ip),
        html->table(html->row('th', @$header) . html->row('td', @$parts), { border => 1 }),
    );
}

sub ip_mask {
    my ($self) = @_;
    my @ip;
    do {
        @ip = map rnd->in_range(0, 255), 1 .. 4;
    } while (0 == grep $_, @ip);
    my @mask = _bits_to_mask(rnd->in_range(1, 31));
    my @header = ('A'..'H');
    my @masked_ip = map $ip[$_] & $mask[$_], 0 .. $#ip;
    my %seen;
    my @parts = sort { $a <=> $b } (grep !$seen{$_}++,
        @masked_ip,
        (map $ip[$_] & $mask[$_], 0 .. $#ip),
        reverse @ip,
        @mask,
        (map $ip[$_] ^ $mask[$_], 0 .. $#ip),
        rnd->pick_n(8, 0..255),
    )[0..$#header];
    ($self->{correct}, my $table_text) = _prepare(\@header, \@parts, \@masked_ip);
    my @example_ip = (192, 168, 128, 0);
    my ($example_answer, $example_table_text) = _prepare(\@header,
        [ 128, 168, 255, 8, 127, 0, 17, 192 ], \@example_ip);
    local $" = '.';
    $self->{text} = <<EOL
В терминологии сетей TCP/IP маской сети называется двоичное число, определяющее,
какая часть IP-адреса узла сети относится к адресу сети, а какая — к адресу самого
узла в этой сети. Обычно маска записывается по тем же правилам, что и IP-адрес.
Адрес сети получается в результате применения поразрядной конъюнкции к заданному
IP-адресу узла и маске. <br/>
По заданным IP-адресу узла и маске определите адрес сети.
<table>
  <tr><td>IP-адрес узла:</td><td>@ip</td></tr>
  <tr><td>Маска:</td><td>@mask</td></tr>
</table>
При записи ответа выберите из приведенных в таблице чисел четыре элемента IP-адреса
и запишите в нужном порядке соответствующие им буквы. Точки писать не нужно.
$table_text
<br/><i><strong>Пример</strong>.
Пусть искомый IP-адрес @example_ip, и дана таблица</i>
$example_table_text
<i>В этом случае правильный ответ будет записан в виде: $example_answer</i>
EOL
}

my $max_func_operand = rnd->in_range(1, 3);
my @func_results = map -1, 1..50;
my $func_eval_code;

sub F {
	my $n = shift;
	return $func_results[$n] if $func_results[$n] >= 0;
	return $func_results[$n] = eval $func_eval_code;
}

sub make_F_text {
	my $res = "F(n-$_[0])";
	$res.='*'.rnd->in_range(2, 3) if rnd->coin();
	return $res;
}

sub make_full_function_text {
	my $res_text = '';
	for (my $i = 0; $i < $max_func_operand; $i++) {
		if ($i == 0) {
			$res_text.=make_F_text(1);
		} elsif ($i == 1) {
			$res_text.=make_F_text($max_func_operand);
		} else {
			$res_text.=make_F_text(rnd->pick(1..$max_func_operand));
		}
		$res_text.='+';
	};
	$res_text.=rnd->in_range(1, 4);
}

sub recursive_function {
	my ($self) = @_;
	my $func_text_code = $func_eval_code = make_full_function_text();
	$func_eval_code =~ s/n/\$n/g;
	my $n = $max_func_operand + rnd->in_range(2, 4);
	for (my $i = 0; $i < $max_func_operand; $i++) {
		$func_results[$i] = rnd->in_range(0, 4);
	}
	$self->{text} = "<p>Алгоритм вычисления значения функции F(n), где ".
					"где n - натуральное число, задан следующими ".
					"соотношениями:</p><div style=\"margin-left:30px\">";
	map $self->{text}.="F($_) = $func_results[$_]<br /> ", 0..$max_func_operand-1;
	$self->{text}.="F(n) = ".$func_text_code.", при n >= $max_func_operand".
					"</div><p>Чему равно значение функции F($n)? В ответе запишите только ".
					"натуральное число.</p>";
	
	$self->{correct} = F($n);
	
	$self->accept_number;	
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item ip_mask

=back


=head2 Генератор ip_mask

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание B11.

=head3 Описание

Дистракторы:

=over

=item *

Числа, полученные при применении поразрядной дизъюнкции (а не конъюнции) к
заданному IP-адресу и маске.

=item *

Числа из IP-адреса.

=item *

Числа из маски.

=back
