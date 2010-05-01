package EGE::Gen::A7;

use strict;
use warnings;
use utf8;

use List::Util;

use EGE::Random;
use EGE::Logic;
use EGE::NumText;
use EGE::Russian::Names;
use EGE::Russian::Animals;

sub make_condition {
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

sub strings {
    my ($next_string, $list_text) = @_;
    my $good = -1;
    my $true_false;
    my $e_text;
    do {
        my ($c1, $c2) = (make_condition());
        do { $c2 = make_condition() } while cond_eq($c1, $c2);
        my ($v1, $v2);
        my $e = EGE::Logic::random_logic_expr_2(\$v1, \$v2);
        $v1 = cond_to_text($c1);
        $v2 = cond_to_text($c2);
        $e_text = $e->to_lang_named('Logic');
        my $min_len = List::Util::max($c1->{n}, $c2->{n});
        $true_false = [ [], [] ];
        while(my $name = $next_string->()) {
            next if length($name) < $min_len;
            $v1 = check_cond($c1, $name);
            $v2 = check_cond($c2, $name);
            push @{$true_false->[$e->run({}) ? 1 : 0]}, $name;
            $good = check_good($true_false);
        }
    } while $good < 0;
    my $tf = $good ? 'истинно' : 'ложно';

    {
        question => "Для какого $list_text $tf высказывание:<br/>$e_text?",
        variants => [ $true_false->[$good][0], @{$true_false->[1 - $good]}[0 .. 2] ],
        answer => 0,
        variants_order => 'random',
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

1;
