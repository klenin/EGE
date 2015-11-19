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

sub bin_to_dec{
	my(@self) = @_;
	my $result;
	for (my $i = 0; $i < 8; $i++){
		$result += $self[$i] * (2 ** $i);
	}
	return $result;
}

sub subnet_mask{
	my ($self) = @_;
	my ($d) = rnd->in_range(1, 6);
	my ($first) = rnd->in_range(200, 255);
	my ($second) = rnd->in_range(30, 255);
	my ($fourth) = rnd->pick(0, rnd->in_range(100, 255));

	my(@mask) = ();
	for (my $i = 0; $i < 8; $i++){        
        	$mask[$i] = $i <= $d ? 0 : 1; 
	}          
    my($mask_third) = bin_to_dec(@mask);
   
	my(@ip) = ();
    $ip[7] = 1;
	for (my $i = 0; $i < 7; $i++){ 
		$ip[$i] = rnd->in_range(0, 1);
	}
	my($ip_third) = bin_to_dec(@ip);

	my (@net_address) = ();
    $net_address[7] = 1;
    for (my $i = 0; $i < 7; $i++) {
        $net_address[$i] = $mask[$i] & $ip[$i];
    }

	my($net_third) = bin_to_dec(@net_address);    

	$self->{text} = <<QUESTION 
Адрес сети получается в результате применения поразрядной конъюнкции к заданному IP-адресу узла и маске. 
Обычно маска записывается по тем же правилам, что и IP-адрес – в виде четырёх байтов, причём каждый байт 
записывается в виде десятичного числа. <br />
Пример. Пусть IP-адрес узла равен 231.32.255.131, а маска равна 255.255.240.0. Тогда адрес сети равен 231.32.240.0. <br />
Для узла с IP-адресом $first.$second.$ip_third.$fourth адрес сети равен $first.$second.$net_third.0.
Чему равен третий слева байт маски? Ответ запишите в виде десятиного числа.
QUESTION
;
    $self->{correct} = $mask_third; 
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
