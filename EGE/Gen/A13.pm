package EGE::Gen::A13;

use strict;
use warnings;
use utf8;

use EGE::Random;

my $q;

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

    my $ext = rnd->pick(qw(txt doc png lst gif jpg map cpp pas bas));
    my $ext_mask = $ext;
    substr($ext_mask, rnd->in_range(0, length($ext) - 1), rnd->coin) = '?';

    my $mask;
    do {
        $mask = join '', rnd->shuffle(rnd->pick_n(2, qw(? ? *)), random_chars(5));
    } while $mask =~ /(\?\*|\*\?)/;
    $mask .= ".$ext_mask";
    (my $bad_mask = $mask) =~ s/(\w)(\w)/$1 . rnd->english_letter . $2/e;

    {
        question => sprintf($q ||= do { undef local $/; <DATA>; }, $mask),
        variants => [ gen_file($bad_mask, 0), map gen_file($mask, $_), 0 .. 2 ],
        answer => 1,
    };
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
Определите, какие из указанных имён файлов удовлетворяют маске <tt>%s</tt>
</p>