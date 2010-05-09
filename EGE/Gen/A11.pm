package EGE::Gen::A11;

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Bits;

sub variable_length {
    my %code = ( 'А' => '00', 'Б' => '11', 'В' => '010', 'Г' => '011' );
    my @letters = sort keys %code;
    my $symt = join(', ', @letters[0 .. $#letters - 1]) . ' и ' . $letters[-1];
    my $codet = join ', ', map "$_ - $code{$_}", @letters;

    my @msg = map rnd->pick(@letters), 1..6;
    my $msgt = join '', @msg;

    my $bs = EGE::Bits->new->set_bin([ map $code{$_}, @msg ]);
    my $bad_bs = EGE::Bits->new->set_bin(
        join '', map substr('000' . $code{$_}, -3), @msg
    );

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
        variants => [ $bs->get_oct, $bs->get_hex, $bad_bs->get_oct, $bads ],
        answer => 0,
        variants_order => 'random',
    };
}

sub fixed_hex {
    my $bits = join '', @_;
    EGE::Bits->new->set_bin($bits)->get_hex;
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
