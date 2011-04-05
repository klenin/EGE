# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A07;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use List::Util;

use EGE::Random;
use EGE::Logic;
use EGE::NumText;
use EGE::Russian::Names;
use EGE::Russian::SimpleNames;
use EGE::Russian::Animals;

use Data::Dumper;

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
    my ($self, $init_string, $next_string, $list_text) = @_;
    my $good = -1;
    my $true_false;
    my $g;
    do {
        $g = make_cond_group;
        $true_false = [ [], [] ];
        $init_string->();
        while(my $str = $next_string->()) {
            next if length($str) < $g->{min_len};
            push @{$true_false->[check_cond_group($g, $str)]}, $str;
            $good = check_good($true_false);
        }
    } while $good < 0;
    my $tf = $good ? 'истинно' : 'ложно';

    $self->{text} = "Для какого $list_text $tf высказывание:<br/>$g->{text}?";
    $self->variants($true_false->[$good][0], @{$true_false->[1 - $good]}[0 .. 2]);
}

sub names {
    my ($self) = @_;
    my @list = rnd->shuffle(@EGE::Russian::Names::list);
    my $i;
    $self->strings(sub { $i = 0 }, sub { $list[$i++] }, 'имени');
}

sub animals {
    my ($self) = @_;
    my @list = rnd->shuffle(@EGE::Russian::Animals::list);
    my $i;
    $self->strings(sub { $i = 0 }, sub { $list[$i++] }, 'из названий животных');
}

sub random_sequences {
    my ($self) = @_;
    my %seen;
    my $gen_seq = sub {
        my $r;
        do {
            $r = join '', map uc rnd->pretty_russian_letter, 1..6;
        } while $seen{$r}++;
        return if keys %seen > 100;
        $r;
    };
    $self->strings(sub { %seen = () }, $gen_seq, 'символьного набора');
}

sub rnd_subpattern {
    $_[0] = '' unless $_[0];
    my $res;
    do {
        $res = uc(rnd->english_letter()) . rnd->in_range(0, 9)
    } while $res eq $_[0];
    $res;
}

sub restore_passwd {
    my ($self) = @_;
    my $OS = rnd->pick("Windows XP", "GNU/Linux", "почтовый аккаунт");
    my $str = join '', map { rnd->pick('A'..'F', 0..9) } 1..5;
    my $ans_str = $str;
    my $sub_init = rnd_subpattern();
    my $sub_good = rnd_subpattern($sub_init);

    my @pos = sort {$b <=> $a} rnd->pick_n(2, 0..(length $str) - 1);
    for (@pos) {
        substr($str, $_, 0, $sub_good);
        substr($ans_str, $_, 0, $sub_init);
    }

    my @good_variants;
    for my $i (1..length $str) {
        my ($res, $b) = (" $str ", 0);
        while ($res =~ s/(\D)\d{$i}(\D)/$1$2/) {
            push @{$self->{variants}}, $res;
            $b = 1;
        }
        push @good_variants, [(pop @{$self->{variants}}), $i] if $b;
    }

    rnd->shuffle(@good_variants);
    my $ans = $good_variants[0];

    @{$self->{variants}} = (
       $ans->[0],
       @{$self->{variants}},
       (map {$_->[0]} @good_variants[1..$#good_variants])
    );

    $self->{text} =
      rnd->pick(@EGE::Russian::SimpleNames::list) .
      " забыл пароль для входа в $OS, но помнил алгоритм его " .
      "получения из символов «$ans_str» в строке подсказки. Если " .
      "последовательность символов «$sub_init» заменить на «$sub_good» " .
      "и из получившейся строки удалить все ".
      ($ans->[1] == 1 ? "одно" : (num_by_words $ans->[1], 1, "genitive")) .
      "значные числа, то полученная последовательность и " .
      "будет паролем: ";

    push @{$self->{variants}}, $ans_str;
    while ($ans_str =~ s/(\D)\d{$ans->[1]}(\D)/$1$2/) {
        push @{$self->{variants}}, $ans_str;
    }
    push @{$self->{variants}}, $sub_good;

    @{$self->{variants}} = @{$self->{variants}}[0..3];

}

1;
