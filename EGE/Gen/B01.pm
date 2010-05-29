# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B01;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::NumText;

sub direct {
    my ($self) = @_;
    my $sig_n = rnd->in_range(2, 5);
    my $sig_text = num_by_words($sig_n, 0, 'genitive');
    my $sec_n = rnd->in_range(2, 5);
    my $sec_text = EGE::NumText::num_by_words_text(
        $sec_n, 1, 'nomivative', [ qw(секунду секунды секунд) ]);
    $self->{text} =
        'Некоторое сигнальное устройство за одну секунду передает один из ' .
        "$sig_text сигналов. Сколько различных сообщений длиной в $sec_text " .
        'можно передать при помощи этого устройства?';
    $self->{correct} = $sig_n ** $sec_n;
    $self->accept_number;
}

1;
