# Copyright © 2010-2011 Alexander S. Klenin
# Copyright © 2011 V. Kevroletin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::A13;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use List::Util qw(reduce);
use Data::Dumper;

my $q;

my @extensions = qw(txt doc png lst gif jpg map cpp pas bas);

sub random_chars { map rnd->english_letter, 1 .. $_[0] }
sub random_str { join '', random_chars @_ }

sub gen_file {
    my ($mask, $bad_q) = @_;
    my $fn = '';
    for my $i (0 .. length($mask) - 1) {
        my $c = substr($mask, $i, 1);
        $fn .=
            $c eq '?' ? random_str(--$bad_q ? 1 : rnd->pick(0, 2, 3)) :
            $c eq '*' ? random_str(rnd->in_range(0, 3)) :
            $c;
    }
    "<tt>$fn</tt>";
}

sub file_mask {
    my ($self) = @_;
    my $ext = rnd->pick(@extensions);
    my $ext_mask = $ext;
    substr($ext_mask, rnd->in_range(0, length($ext) - 1), rnd->coin) = '?';

    my $mask;
    do {
        $mask = join '', rnd->shuffle(rnd->pick_n(2, qw(? ? *)), random_chars(5));
    } while $mask =~ /(\?\*|\*\?)/;
    $mask .= ".$ext_mask";
    (my $bad_mask = $mask) =~ s/(\w)(\w)/$1 . rnd->english_letter . $2/e;

    my $t = $q ||= do { undef local $/; <DATA>; };
    $t .= "Определите, какие из указанных имён файлов удовлетворяют маске <tt>%s</tt>";

    $self->{text} = sprintf($t, $mask);
    $self->variants(gen_file($bad_mask, 0), map gen_file($mask, $_), 0 .. 2);
    $self->{correct} = 1;
}

sub exact_gen_file {
    my ($mask, $ok) = @_;
    my $fn = '';
    for my $i (0 .. length($mask) - 1) {
        my $c = substr($mask, $i, 1);
        $fn .=
            $c eq '?' ? random_str($ok ? 1 : rnd->pick(0, 2, 3)) :
            $c eq '*' ? random_str(rnd->in_range(0, 3)) :
            $c;
    }
    $fn;
}

sub mask_to_regexp {
    my ($mask) = @_;
    $mask =~ s/\*/.*/g;
    $mask =~ s/\?/./g;
    "^$mask\$";
}

sub gen_names {
    my ($masks, $patterns, $good, $count) = @_;
    my @res;
    my $check = [ sub {
                      my ($a, $b, $f) = @_;
                      $a || ($f !~ $b);
                  },
                  sub {
                      my ($a, $b, $f) = @_;
                      $a && ($f =~ $b);
                  }]->[$good];
    my $i = 0;
    my %used;
    while (@res < $count) {
        my $f = exact_gen_file($masks->[$i], $good);
        next if $used{$f};
        if (reduce { $check->($a, $patterns->[$b], $f) } $good, 0 .. 3) {
            push @res, $f;
            $used{$f} = 1;
        }
        $i = ($i + 1) % $count;
    }
    @res;
}

sub put_mask_to_s {
    my ($s, $m, $pos) = @_;
    my $t = $s;
    substr($t, $pos->[$_], 1) = $m->[$_] for 0..$#$pos;
    $t;
}

sub select_pos {
    my ($len, $metachars) = @_;
    my @pos;
    do {
        @pos = sort { $b <=> $a } rnd->pick_n($metachars, 0 .. $len - 1)
    } while $metachars > 1 && $pos[0] == $pos[1] + 1;
    @pos;
}

sub gen_masks {
    my ($s, $metachars) = @_;
    my @pos = select_pos((length $s), $metachars);
    my $was_q = 0;
    my @res;
    do {
        @res = map {
            my @m = map { rnd->pick(qw(? *)) } 1 .. $metachars;
            $was_q |= ($_ eq '?') for @m;
            [@m];
        } 1 .. 4;
    } while !$was_q;
    map { put_mask_to_s($s, $_, \@pos) } @res;
}

sub join_arr { map { my $i = $_; map "$i.$_", @{$_[1]} } @{$_[0]}; }

sub gen_good_bad_names {
    my ($s, $metachars) = @_;
    my @masks = gen_masks($s, $metachars);
    my @patterns = map mask_to_regexp($_), @masks;
    my @good = gen_names(\@masks, \@patterns, 1, 1);
    my @bad = gen_names(\@masks, \@patterns, 0, 2);
    (\@masks, \@good, \@bad);
}

sub file_mask2 {
    my ($self) = @_;
    my $s = random_str(rnd->in_range(5, 8));
    my $ext = rnd->pick(@extensions);

    my ($base_masks, $good_base, $bad_base) = gen_good_bad_names($s, 2);
    my ($ext_masks, $good_ext, $bad_ext) = gen_good_bad_names($ext, 1);

    my @good_ans = join_arr $good_base, $good_ext;
    my @bad_ans = (
        join_arr($good_base, $bad_ext),
        join_arr($bad_base, $good_ext),
        join_arr($bad_base, $bad_ext));
    $self->variants(@good_ans, rnd->pick_n(3, @bad_ans));

    my $t = $q ||= do { undef local $/; <DATA>; };
    $self->{text} = join '',
        $t, ' Определите, какой из указанных файлов удовлетворяет всем маскам:<ul>',
        map("<li>$base_masks->[$_].$ext_masks->[$_] </li>", 0..3),
        '</ul>';
}

sub gen_masks_names {
    my ($s, $metachars) = @_;
    my @pos = select_pos((length $s), $metachars);
    my $mask_arr = [
        [ [ '*' ], [ '?' ] ],
        [ [ '*', '*' ], [ '*', '?' ], [ '?', '*' ], [ '?', '?' ] ],
    ]->[$metachars - 1];
    my @masks = map { put_mask_to_s($s, $_, \@pos) } @$mask_arr;
    my @names = map { exact_gen_file($_, 0) } @masks;
    (\@masks, \@names);
}

sub file_mask3 {
    my ($self) = @_;

    my $s = random_str(rnd->in_range(5, 8));
    my $ext = rnd->pick(@extensions);
    my ($base_masks, $base_names) = gen_masks_names($s, 2);
    my ($ext_masks, $ext_names) = gen_masks_names($ext, rnd->pick(1, 2));

    my ($good, @bad) = join_arr($base_masks, $ext_masks);
    $self->{variants} = [ $good, rnd->pick_n(3, @bad) ];

    # FIXME: Правильный ответ содержит только *.
    my $t = $q ||= do { undef local $/; <DATA>; };
    $self->{text} = "$t Определите, по какой из масок будет выбрана указанная группа файлов: <ul>";
    $self->{text} .= "<li>$base_names->[$_].$ext_names->[$_]</li>" for 0 .. 1;
    $self->{text} .= "</ul>";
}

1;

__DATA__
<p>Для групповых операций с файлами используются <b>маски имён файлов</b>.
Маска представляет собой последовательность букв, цифр, и прочих допустимых
в именах файлов символов, в которой также могут встречаться следующие символы:
</p>
<p>Символ «?» (вопросительный знак) означает ровно один произвольный символ.
</p>
<p>Символ «*» (звёздочка) означает любую последовательность символов произвольной длины,
в том числе и пустую последовательность.
</p>
