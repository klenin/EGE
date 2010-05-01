package EGE::Gen::A7;

use strict;
use warnings;
use utf8;

use List::Util;

use EGE::Random;
use EGE::Logic;
use EGE::NumText;
use EGE::Russian::Names;

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
    for (0 .. 1) {
        return $_ if @{$tf->[$_]} && @{$tf->[1 - $_]} >= 3;
    }
    -1;
}

sub names {
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
        my @candidates = rnd->shuffle(@EGE::Russian::Names::list);
        my $min_len = List::Util::max($c1->{n}, $c2->{n});
        $true_false = [ [], [] ];
        for my $name (@candidates) {
            next if length($name) < $min_len;
            $v1 = check_cond($c1, $name);
            $v2 = check_cond($c2, $name);
            push @{$true_false->[$e->run({}) ? 1 : 0]}, $name;
            $good = check_good($true_false);
        }
    } while $good < 0;
    my $tf = $good ? 'истинно' : 'ложно';
    {
        question => "Для какого имени $tf высказывание:<br/>$e_text?",
        variants => [ $true_false->[$good][0], @{$true_false->[1 - $good]}[0 .. 2] ],
        answer => 0,
        variants_order => 'random',
    };
}

1;
