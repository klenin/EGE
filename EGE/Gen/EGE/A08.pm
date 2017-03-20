# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A08;
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
    ($e, $e->to_lang_named('Logic', { html => 1 }));
}

sub equiv_common {
    my ($self, @vars) = @_;
    my ($e, $e_text) = rand_expr_text(@vars);
    my $e_tts = tts($e);
    my %seen = ($e_text => 1);
    my (@good, @bad);
    until (@good && @bad >= 3) {
        my ($e1, $e1_text);
        if (@bad > 30) {
            # случайный перебор может работать долго, поэтому
            # через некоторое время применяем эквивалентное преобразование
            $e1 = EGE::Logic::equiv_not($e);
            $e1_text = $e1->to_lang_named('Logic', { html => 1 });
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

sub equiv_3 { $_[0]->equiv_common(qw(A B C)) }

sub equiv_4 { $_[0]->equiv_common(qw(A B C D)) }

sub _audio_data {
    my %data = (
        freq  => rnd->pick(8, 11, 16, 22, 32, 44, 48, 50, 96, 176, 192),
        resol => 8 * rnd->in_range(2, 10),
        time_ => rnd->in_range(1, 10),
        channels_n => rnd->in_range(0, 2),
    );

    my @w = ('одноканальная (моно)', 'двухканальная (стерео)', 'четырехканальная (квадро)');
    $data{channels_word} = $w[$data{channels_n}];

    $data{time_word} = num_text($data{time_}, [qw(минуту минуты минут)]);
    $data{size} = 2 ** $data{channels_n} * $data{freq} * 1000 * $data{resol} * $data{time_} * 60.0 / 8;
    %data;
}

sub _audio_bad_ans {
    rnd->pick_n(3, grep $_ >= 1, map $_[0] * $_, 0.1, 0.2, 0.25, 0.5, 2, 3, 4, 5, 10);
}

sub _audio_out {
    my ($data, $size, @units) = @_; 
    while ($data > $size) { $data /= $size; shift @units; }
    map { sprintf '%.1f %s', $_, $units[0] } $data, _audio_bad_ans($data);
}

sub audio_size {
    my ($self) = @_;
    my %data = _audio_data;

    $self->{text} = 
        "Производится $data{channels_word} звукозапись с частотой дискретизации " .
        "$data{freq} кГц и $data{resol}-битным разрешением. " .
        "Запись длится $data{time_word}, ее результаты записываются " .
        'в файл, сжатие данных не производится. ' .
        'Какая из приведенных ниже величин наиболее близка к размеру полученного файла?';

    my @units = qw(Байт Кбайт Мбайт Гбайт);
    $self->variants(_audio_out($data{size}, 1024, @units));
}

sub audio_time {
    my ($self) = @_;
    my %data = _audio_data;

    $self->{text} = sprintf
        'Производится %s звукозапись с частотой дискретизации ' . 
        '%s кГц и %s-битным разрешением. Результаты записи записываются в файл, ' .
        'размер полученного файла — %s байт; сжатие данных не производилось. ' .
        'Какая из приведенных ниже величин наиболее близка к времени, в течение которого происходила запись?',
        $data{channels_word}, $data{freq}, $data{resol}, $data{size};

    my @units = qw(сек мин ч);
    $self->variants(_audio_out($data{time_}, 60, @units));
}

1;
