# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A16;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use List::Util qw(sum);

use EGE::Random;

sub spreadsheet {
    my ($self) = @_;
    my @len;
    $len[2] = rnd->pick(5, 6);
    $len[0] = rnd->in_range(1, $len[2] - 1);
    $len[1] = $len[2] - $len[0];
    my @ofs = (0, $len[0], 0);
    my @cells = map rnd->in_range(1, 8), 1 .. $len[2];
    my $start = rnd->in_range(1, 3);
    my $cell_name =
        rnd->pick(
            sub { ['A' .. 'Z']->[$_[0]] . $start },
            sub { ['A' .. 'Z']->[$start - 1] . ($_[0] + 1) });
    my @cn = map $cell_name->($_), 0 .. $len[2] - 1;
    my (@descr, @values);
    for my $i (0 .. $#len) {
        if ($len[$i] == 1) {
            $values[$i] = $cells[$ofs[$i]];
            $descr[$i] = "значение ячейки $cn[$ofs[$i]]";
        }
        else {
            my $r = $ofs[$i] + $len[$i] - 1;
            $values[$i] = sum @cells[$ofs[$i] .. $r];
            my $f = 'СУММ';
            if ($values[$i] % $len[$i] == 0) {
                $f = 'СРЗНАЧ';
                $values[$i] /= $len[$i];
            }
            $descr[$i] = "значение формулы $f($cn[$ofs[$i]]:$cn[$r])";
        }
    }

    my @order = rnd->shuffle(0 .. 2);

    my @bad;
    my %seen = ( $values[$order[1]] => 1 );
    for my $i (0 .. $len[2] - 1) {
        for my $j ($i .. $len[2] - 1) {
            my $s = sum @cells[$i .. $j];
            push @bad, $s unless $seen{$s}++;
            next if $j == $i || $s % ($j - $i + 1);
            $s /= $j - $i + 1;
            push @bad, $s unless $seen{$s}++;
        }
    }

    $self->{text} = sprintf
        'В электронной таблице %1$s равно %2$s. ' .
        'Чему равно %3$s, если %5$s равно %6$s?' ,
        map { $descr[$order[$_]], $values[$order[$_]] } 0 .. 2;
    $self->variants($values[$order[1]], rnd->pick_n(3, @bad));
}

1;
