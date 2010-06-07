# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::B02;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Flowchart;

sub flow1 {
    my ($self) = @_;
    my $b = EGE::Prog::make_block([
        '=', 'a', '256',
        '=', 'b', 0,
        '=', 'a', [ '/', 'a', 2 ],
        '=', 'b', [ '+', 'b', 'a' ],
    ]);
    $self->{text} =
        'Запишите значение переменной b после выполнения фрагмента алгоритма:' .
        $b->as_svg .
        '<i>Примечание: знаком “:=” обозначена операция присваивания</i>';
    $self->{correct} = $b->run_val('b');
    $self->accept_number;
}

1;
