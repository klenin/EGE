# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A08;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Logic;
use EGE::NumText;

sub tts { EGE::Logic::truth_table_string($_[0]) }

sub rand_expr_text {
    my $e = EGE::Logic::random_logic_expr(@_);
    ($e, $e->to_lang_named('Logic'));
}

sub equiv_common {
    my ($self, @vars) = @_;
    my ($e, $e_text) = rand_expr_text(@vars);
    my $e_tts = tts($e);
    my %seen = ($e_text => 1);
    my (@good, @bad);
    until (@good && @bad >= 3) {
        my ($e1, $e1_text);
        if (@bad > 300) {
            # случайный перебор может работать долго, поэтому
            # через некоторое время применяем эквивалентное преобразование
            $e1 = EGE::Logic::equiv_not($e);
            $e1_text = $e1->to_lang_named('Logic');
        }
        else {
            do {
                ($e1, $e1_text) = rand_expr_text(@vars);
            } while $seen{$e1_text}++;
        }
        tts($e1) eq $e_tts ? push @good, $e1_text : push @bad, $e1_text;
    }
    $self->{text} = "Укажите, какое логическое выражение равносильно выражению $e_text.",
    $self->variants($good[0], @bad[0..2]);
}

sub equiv_3 { $_[0]->equiv_common qw(A B C) }

sub equiv_4 { $_[0]->equiv_common qw(A B C D) }

sub audio_sampling {
    my ($self) = @_;
    my $freq  = rnd->pick(8, 11, 16, 22, 32, 44, 48, 50, 96, 176, 192);
    my $resol = rnd->pick(map { $_ * 8 } 2 .. 10);
    my $time_sec = $_ = rnd->in_range(1, 10);
    my $time = num_text($_, [qw(минуту минуты минут)]);

    $self->{text} = sprintf
        'Производится одноканальная (моно) звукозапись с частотой дискретизации ' .
        '%s кГц и %s-битным разрешением. Запись длится %s, ее результаты записываются' .
        ' в файл, сжатие данных не производится. Какая из приведенных ниже величин' .
        ' наиболее близка к размеру полученного файла?',
            $freq, $resol, $time;

    my @units = (qw(Байт Кбайт Мбайт Гбайт));
    $_ = $freq * 1000 * $resol * $time_sec * 60.0 / 8;
    while (int($_ / 1024) > 0) { $_ /= 1024; shift @units };
    my $t  = sprintf "%0.0f", $_;
    my $t1 = sprintf "%0.0f", $_ / 10;
    my $t2 = sprintf "%0.0f", $_ * 10;
    my @bad_res =  rnd->shuffle( grep { $_ > 0 } $t-1, $t+1, $t1, $t1-1, $t1+1, $t2, $t2-1, $t2+2 );
    $self->variants( map { $_ . ' ' . $units[0] } $t, @bad_res[0 .. 2] );
}

1;

