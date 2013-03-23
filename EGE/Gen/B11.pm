# Copyright © 2010-2012 Alexander S. Klenin
# Copyright © 2012 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::B11;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Html;

use List::Util qw(sum max);


sub _bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub _pack8 {
    my (@res, $t);
    for (@_) {
        $t .= $_;
        if (length($t) == 8) {
            push @res, $t;
            $t = '';
        }
    }
    push @res, $t if $t;
    map { _bin2dec($_) } @res
}

sub _double_map {
    my ($funct, $ar1, $ar2) = @_;
    my $i = 0;
    my @res;
    while ($i < max(int @$ar1, int @$ar2)) {
        push @res, $funct->($ar1->[$i], $ar2->[$i]);
        ++$i;
    }
    \@res
}

sub _table_text {
    my ($table) = @_;
    $_  = html->row('th', 'A' .. 'H');
    $_ .= html->row('td', @{$table});
    html->table($_, {border => 1});
}

sub ip_mask {
    my ($self) = @_;
    my $ip;
    do {
        $ip = [map { rnd->in_range(0, 255) } 1 .. 4];
    } while (sum @$ip == 0);
    my $mask_ones_cnt = rnd->in_range(1, 31);
    my $mask = [_pack8 map { $_ > $mask_ones_cnt ? 0 : 1 } 1 .. 32];
    my $res  = _double_map( sub { $_[0] & $_[1] }, $ip, $mask );
    my @tbl = ( @$res,
                @{ _double_map( sub { $_[0] | $_[1] }, $ip, $mask ) },
                reverse @$ip,
                @$mask,
                @{ _double_map( sub { $_[0] ^ $_[1] }, $ip, $mask ) });
    my %seen;
    @tbl = grep { !$seen{$_}++ } @tbl;
    while (@tbl < 8) {
        $_ = rnd->in_range(0, 255);
        push @tbl, $_ unless $_ ~~ @tbl
    }
    @tbl = sort { $a <=> $b } @tbl[0 .. 7];
    $self->{correct} = '';
    for my $x (@{$res}) {
        $self->{correct} .= join '', map { ['A' .. 'H']->[$_] }
            grep { $tbl[$_] == $x } 0 .. $#tbl;
    }

    my ($ip_text, $mask_text) = map { join '.', @$_ } $ip, $mask;
    my $table_text = _table_text(\@tbl); 
    my $example_table_text = _table_text([128, 168, 255, 8, 127, 0, 17, 192]);
    $self->{text} = <<EOL
В терминологии сетей TCP/IP маской сети  называется двоичное число, определяющее,
какая часть IP-адреса узла сети относится к адресу сети, а какая — к адресу самого
узла в этой сети. Обычно маска записывается по тем же правилам, что и IP-адрес.
Адрес сети получается в результате применения поразрядной конъюнкции к заданному
IP-адресу узла и маске. <br/>
По заданным  IP-адресу узла и маске  определите адрес сети.
<table>
  <tr><td>IP –адрес узла:</td><td>$ip_text</td></tr>
  <tr><td>Маска:</td><td>$mask_text</td></tr>
</table>
При записи ответа выберите из приведенных в таблице чисел четыре элемента IP-адреса
и запишите в нужном порядке соответствующие им буквы. Точки писать не нужно.
$table_text
<br/><i><strong>Пример</strong>.
Пусть искомый IP-адрес  192.168.128.0, и дана таблица
$example_table_text
В этом случае правильный ответ будет записан в виде: HBAF
</i>
EOL
}

1;

__END__

=pod

=head1 Список генераторов

=over

=item ip_mask

=back


=head2 Генератор car_numbers

=head3 Источник

Демонстрационные варианты ЕГЭ по информатике 2012, официальный информационный
портал ЕГЭ. Задание B11.

=head3 Описание

Деструкторы:

=over

=item *

Числа, полученные при применении поразрядной дизъюнкции(а не конъюнции) к
заданному IP-адресу и маске.

=item *

Числа из IP-адреса.

=item *

Числа из маски.

=back
