# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::NumText;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(num_text num_bits num_bytes bits_and_bytes num_by_words);

my $words = {
    nominative => {
        s0 => 'ноль',
        s1 => [ [ qw(один два) ], [ qw(одна две) ], [ qw(одно два) ] ],
        s2 => [ qw(три четыре пять шесть семь восемь девять) ],
        s3 => [ 'десять',
            map $_ . 'надцать', qw(один две три четыр пят шест сем восем девят) ],
        s4 => [ qw(
            двадцать тридцать сорок пятьдесят шестьдесят семьдесят восемьдесят девяносто) ],
        s5 => [ qw(
            сто двести триста четыреста пятьсот шестьсот семьсот восемьсот девятьсот) ],
    },
    genitive => {
        s0 => 'ноля',
        s1 => [ [ qw(одного двух) ], [ qw(одной двух) ], [ qw(одного двух) ] ],
        s2 => [ qw(трёх четырёх пяти шести семи восьми девяти) ],
        s3 => [ 'десяти',
            map $_ . 'надцати', qw(один две три четыр пят шест сем восем девят) ],
        s4 => [ qw(
            двадцати тридцати сорока пятидесяти шестидесяти семидесяти восьмидесяти девяноста) ],
        s5 => [ qw(
            ста двухсот трёхсот четырёхсот пятисот шестисот семисот восьмисот девятисот) ],
    },
};

sub num_by_words {
    my ($num, $gender, $case) = @_;
    $case = $words->{$case || ''} || $words->{nominative};
    $num or return $case->{s0};
    0 < $num && $num < 1000 or die;
    my @r;
    push @r, $case->{s5}->[$num / 100 - 1] if $num >= 100;
    $num %= 100;
    if ($num >= 20) {
        push @r, $case->{s4}->[$num / 10 - 2];
        $num %= 10;
    }
    elsif ($num >= 10) {
        push @r, $case->{s3}->[$num - 10];
        $num = 0;
    }
    if ($num >= 3) {
        push @r, $case->{s2}->[$num - 3];
    }
    elsif ($num >= 1) {
        push @r, $case->{s1}->[$gender]->[$num - 1];
    }
    join ' ', @r;
}

sub num_text {
    my ($n, $ts, $text_only) = @_;
    my $d = $n % 10;
    my $t =
        10 <= $n && $n <= 20 ? 2 :
        $d == 1 ? 0 :
        $d =~ /^2|3|4$/ ? 1 :
        2;
   ($text_only ? '' : "$n ") . $ts->[$t];
}

sub num_by_words_text {
    my ($n, $gender, $case, $forms) = @_;
    num_by_words($n, $gender, $case) . ' ' . num_text($n, $forms, 1);
}

sub num_bits { num_text($_[0], [ 'бит', 'бита', 'бит' ]) }
sub num_bytes { num_text($_[0], [ 'байт', 'байта', 'байтов' ]) }

sub bits_and_bytes { num_bytes($_[0]), num_bits($_[0] * 8) }

1;
