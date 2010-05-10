# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A07;

use strict;
use warnings;
use utf8;

use List::Util;

use EGE::Random;
use EGE::Logic;
use EGE::NumText;
use EGE::Russian::Names;
use EGE::Russian::Animals;

sub make_condition() {
    {
        n => rnd->in_range(1, 5),
        type => (rnd->in_range(1, 6) > 1 ? 1 : 2),
        vc => rnd->coin,
    }
}

sub cond_to_text {
    my ($cond) = @_;
    my @pos_names = qw(Первая Вторая Третья Четвёртая Пятая Шестая);
    my @count_names = qw(одна две три четыре пять шесть);
    my @letters = ('гласная буква', 'гласных буквы', 'гласных букв');

    my $vc = $cond->{vc} ? 'со' : '';
    $cond->{type} == 1 ?
        $pos_names[$cond->{n} - 1]  . " буква ${vc}гласная" :
        'В слове ' . num_text($cond->{n}, [ map "$vc$_", @letters ]);
}

sub letter_vc { substr($_[0], $_[1], 1) =~ /[аеёиоуыэюя]/i ? 0 : 1; }
sub count_vc { 0 + grep letter_vc($_[0], $_) == $_[1], 0 .. length($_[0]) - 1 }

sub check_cond {
    my ($cond, $str) = @_;

    my $vc = $cond->{vc}; 
    my $r = $cond->{type} == 1 ?
        letter_vc($str, $cond->{n} - 1) == $vc :
        $cond->{n} == count_vc($str, $vc);
    $r ? 1 : 0;
}

sub cond_eq {
    my ($cond1, $cond2) = @_;
    for (keys %$cond1) {
        return 0 if $cond1->{$_} ne $cond2->{$_};
    }
    1;
}

sub check_good {
    my ($tf) = @_;
    for (rnd->shuffle(0, 1)) {
        return $_ if @{$tf->[$_]} && @{$tf->[1 - $_]} >= 3;
    }
    -1;
}

sub make_cond_group {
    my $g = { size => rnd->pick(2, 3) };
    my $v = $g->{vars} = [ (0) x $g->{size} ];
    $g->{expr} = EGE::Logic::random_logic_expr(map \$_, @$v);
    my $c = $g->{cond} = [ make_condition ];
    for (2 .. $g->{size}) {
        my $new_cond;
        do {
            $new_cond = make_condition;
        } while grep cond_eq($_, $new_cond), @$c;
        push @$c, $new_cond;
    }
    $v->[$_] = cond_to_text($c->[$_]) for 0 .. $g->{size} - 1;
    $g->{text} = $g->{expr}->to_lang_named('Logic');
    $g->{min_len} = List::Util::max(map $_->{n}, @$c);
    $g;
}

sub check_cond_group {
    my ($g, $str) = @_;
    $g->{vars}->[$_] = check_cond($g->{cond}->[$_], $str)
        for 0 .. $g->{size} - 1;
    $g->{expr}->run({}) ? 1 : 0;
}

sub strings {
    my ($next_string, $list_text) = @_;
    my $good = -1;
    my $true_false;
    my $g;
    do {
        $g = make_cond_group;
        $true_false = [ [], [] ];
        while(my $str = $next_string->()) {
            next if length($str) < $g->{min_len};
            push @{$true_false->[check_cond_group($g, $str)]}, $str;
            $good = check_good($true_false);
        }
    } while $good < 0;
    my $tf = $good ? 'истинно' : 'ложно';

    {
        question => "Для какого $list_text $tf высказывание:<br/>$g->{text}?",
        variants => [ $true_false->[$good][0], @{$true_false->[1 - $good]}[0 .. 2] ],
        answer => 0,
    };
}

sub names {
    my @list = rnd->shuffle(@EGE::Russian::Names::list);
    my $i = 0;
    strings(sub { $list[$i++] }, 'имени');
}

sub animals {
    my @list = rnd->shuffle(@EGE::Russian::Animals::list);
    my $i = 0;
    strings(sub { $list[$i++] }, 'из названий животных');
}

sub random_sequences {
    my %seen = ();
    my $gen_seq = sub {
        my $r;
        do {
            $r = join '', map uc rnd->pretty_russian_letter, 1..6;
        } while $seen{$r}++;
        if (keys %seen > 100) {
            %seen = ();
            return;
        }
        $r;
    };
    strings($gen_seq, 'символьного набора');
}

1;
