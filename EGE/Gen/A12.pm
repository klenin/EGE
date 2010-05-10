package EGE::Gen::A12;

use strict;
use warnings;
use utf8;

use EGE::Random;

sub except {
    my ($all, $except) = @_;
    my %h;
    @h{@$all} = undef;
    delete $h{$_} for @$except;
    keys %h;
}

sub beads {
    my @all = rnd->pick_n_sorted(5, 'A' .. 'Z');
    my $len = 3;
    my @order = rnd->shuffle(0 .. $len - 1);
    my @subsets = map [ rnd->pick_n_sorted(rnd->pick(3, 4), @all) ], 1 .. $len;

    my $gen = sub {
        my ($bad_stage) = @_;
        my $letter = $bad_stage ? '' : rnd->pick(except \@all, $subsets[0]);
        my @r;
        for my $i (0 .. $len - 1) {
            $letter = rnd->pick(grep $_ ne $letter, @{$subsets[$i]})
                if $bad_stage != $i;
            $r[$order[$i]] = $letter;
        }
        join '', @r;
    };

    my @one_of_beads = map 'одна из бусин ' . join(', ', @$_), @subsets;

    my @pos_names = (
        [ 'в начале цепочки', 'на первом месте', ],
        [ 'в середине цепочки', 'не втором месте', ],
        [ 'в конце цепочки', 'на последнем месте', 'на третьем месте', ],
    );
    my $pos_name = sub { rnd->pick(@{$pos_names[$order[$_[0]]]}) };

    my $rule = ucfirst($pos_name->(0)) . " стоит $one_of_beads[0]. ";
    for (1 .. $len - 1) {
        $rule .=
            sprintf '%s — %s, %s %s. ',
            ucfirst($pos_name->($_)), $one_of_beads[$_],
            rnd->pick('которой нет', 'не стоящая'), $pos_name->($_ - 1);
    }

    {
        question =>
            'Цепочка из трёх бусин, помеченных латинскими буквами, ' .
            "формируется по следующему правилу. $rule" .
            'Какая из перечисленных цепочек создана по этому правилу?'
            ,
        variants => [ map $gen->($_ - 1), 0 .. $len ],
        answer => 0,
    };
}

1;
