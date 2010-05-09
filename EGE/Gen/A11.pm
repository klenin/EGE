package EGE::Gen::A11;

use strict;
use warnings;
use utf8;

use Bit::Vector;
use Bit::Vector::String;
use EGE::Random;

sub variable_length {
    my %code = ( 'А' => '00', 'Б' => '11', 'В' => '010', 'Г' => '011' );
    my @letters = sort keys %code;
    my $symt = join(', ', @letters[0 .. $#letters - 1]) . ' и ' . $letters[-1];
    my $codet = join ', ', map "$_ - $code{$_}", @letters;

    my @msg = map rnd->pick(@letters), 1..6;
    my $msgt = join '', @msg;

    my $bits = join '', map $code{$_}, @msg;
    my $bv = Bit::Vector->new_Bin(length($bits), $bits);

    my $bad_bits = join '', map substr('000' . $code{$_}, -3), @msg;
    my $bad_bv = Bit::Vector->new_Bin(length($bad_bits), $bad_bits);

    my $c = 'A';
    my %bad_letters = map { $_ => $c++ } @letters;
    my $bads = join '', map $bad_letters{$_}, @msg;

    {
        question =>
            'Для передачи по каналу связи сообщения, состоящего только из ' .
            "символов $symt, используется неравномерный (по длине) код: $codet. " .
            "Через канал связи передаётся сообщение: $msgt. " .
            'Закодируйте соощение данным кодом. ' .
            'Полученную двоичную последовательность переведите в восьмеричный вид.'
            ,
        variants => [ $bv->to_Oct, $bv->to_Hex, $bad_bv->to_Oct, $bads ],
        answer => 0,
        variants_order => 'random',
    };
}

sub fixed_hex {
    my $bits = join '', @_;
    Bit::Vector->new_Bin(length($bits), $bits)->to_Hex;
}

sub fixed_length {
    my %code = ( 'А' => '00', 'Б' => '01', 'В' => '10', 'Г' => '11' );
    my @letters = sort keys %code;
    my $symt = join ', ', @letters;

    my @msg = map rnd->pick(@letters), 1..4;
    my $msgt = join '', @msg;

    my $good = fixed_hex map $code{$_}, @msg;
    my @bad = map fixed_hex(@$_),
        [ map $code{$_}, rnd->shuffle(@msg) ],
        [ map "00$code{$_}", @msg ],
        [ map "$code{$_}00", @msg ];

    {
        question =>
            "Для кодирования букв $symt решили использовать двухразрядные " .
            'последовательные двоичные числа (от 00 до 11, соответственно). ' .
            "Если таким способом закодировать последовательность символов $msgt и " .
            'записать результат в шестнадцатеричной системе счисления, то получится',
        variants => [ $good, @bad ],
        answer => 0,
        variants_order => 'random',
    };
}

1;
