# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::EGE::B04;
use base 'EGE::GenBase::DirectInput';

use strict;
use warnings;
use utf8;

use List::Util qw(sum first min max);
use POSIX qw(ceil);

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::NumText;
use EGE::Utils qw(product);

sub make_xx {[
    '*', map rnd->pick('X', [ '+', 'X', 1 ], [ '-', 'X', 1 ]), 1 .. 2
]}

sub make_side {
    [ rnd->pick(qw(> < >= <=)), make_xx(), rnd->in_range(30, 99) ]
}

sub find_first {
    my ($v, $q) = @_;
    $q->[$_] == $v and return $_ for 0 .. $#$q;
    -1;
}

sub find_last {
    my ($v, $q) = @_;
    $q->[-$_] == $v and return @$q - $_ for 1 .. @$q;
    -1;
}

sub between { $_[1] <= $_[0] && $_[0] <= $_[2] }

sub impl_border {
    my ($self) = @_;
    my $n = 15;

    my ($e, @values);
    do {
        $e = EGE::Prog::make_expr([ '=>', make_side, make_side ]);
        @values = map $e->run({ X => $_ }), 0 .. $n;
    } until between sum(@values), 1, $n;

    my $et = html->cdata($e->to_lang_named('Logic'));

    my $facet = first { between $_->{v}, 1, $n - 1 } rnd->shuffle(map {
        t1 => [ qw(наименьшее наибольшее) ]->[$_ / 2],
        t2 => [ qw(ложно истинно) ]->[$_ % 2],
        v => ($_ < 2 ? \&find_first : \&find_last)->($_ % 2, \@values),
    }, 0 .. 3);
    $self->{text} =
        "Каково $facet->{t1} целое число X, " .
        "при котором $facet->{t2} высказывание $et?";
    $self->{correct} = $facet->{v};
    $self->accept_number;
}

sub _next_ptrn_lex {
    my ($ptrn, $alph_len) = @_;
    my $i = $#$ptrn;
    while ($i > -1 && $ptrn->[$i] == $alph_len - 1) {
        $ptrn->[$i--] = 0
    }
    ++$ptrn->[$i] if $i > -1;
    $i == -1 ? undef : $ptrn
}

sub _prev_ptrn_lex {
    my ($ptrn, $alph_len) = @_;
    my $i = $#$ptrn;
    while ($i > -1 && !$ptrn->[$i]) {
        $ptrn->[$i--] = $alph_len - 1
    }
    --$ptrn->[$i] if $i > -1;
    $i == -1 ? undef : $ptrn
}

sub _ptrn_to_str {
    my ($ptrn, $alph) = @_;
    join '', map { $alph->[$_] } @$ptrn
}

sub lex_order {
    my ($self) = @_;
    my $alph_len = rnd->in_range(3, 5);
    my $ptrn_len = rnd->in_range(4, 6);
    my $delta = rnd->in_range(1, $alph_len);
    my $alph = [sort( rnd()->pick_n($alph_len, qw(А Е И О У Э Ю Я)) )];

    my $ptrn = [($alph_len - 1) x $ptrn_len];
    _prev_ptrn_lex($ptrn, $alph_len) for 1 .. $delta;
    $self->{correct} = _ptrn_to_str($ptrn, $alph);
    my $pos = $alph_len**$ptrn_len - $delta;

    $ptrn = [(0) x $ptrn_len];
    my $ptrn_list = html->li( _ptrn_to_str($ptrn, $alph) );
    for (0 .. $alph_len - 1) {
        _next_ptrn_lex($ptrn, $alph_len);
        $ptrn_list .= html->li( _ptrn_to_str($ptrn, $alph) );
    }
    $ptrn_list = html->ol( $ptrn_list . html->li('...') );

    my $alph_text = (join ', ', @$alph);
    $self->{text} =
        "Все $ptrn_len-буквенные слова, составленные из букв $alph_text, записаны" .
        " в алфавитном порядке.<br/>Вот начало списка: $ptrn_list Запишите слово," .
        " которое стоит на <strong>$pos-м месте</strong> от начала списка."
}

sub morse {
    my($self) = @_;
    my $first = rnd->in_range(2, 6);
    my $second = rnd->in_range($first + 1, 10);

    $self->{text} = <<QUESTION
Азбука Морзе позволяет кодировать символы для сообщений по радиосвязи, задавая комбинацию точек и тире.
Сколько различных символов (цифр, букв, знаков пунктуации и т.д.) можно закодировать,
используя код азбуки Морзе длиной не менее $first и не более $second сигналов (точек и тире)?
QUESTION
;
    my $answer = 0;
    $answer += 2 ** $_ for $first..$second;
    $self->{correct} = $answer;
    $self->accept_number;
}

sub bulbs {
    my($self) = @_;
    my $count = rnd->in_range(3, 100);

    $self->{text} =
        'Световое табло состоит из лампочек. Каждая лампочка может находиться в одном из трех состояний ' .
        '(«включено», «выключено» или «мигает»). Какое наименьшее количество лампочек должно находиться ' .
        "на табло, чтобы с его помощью можно было передать $count различных сигналов?";

    $self->{correct} = ceil(log($count) / log(3));
    $self->accept_number;
}

sub plus_minus {
    my($self) = @_;
    my $num = rnd->in_range(5, 10);
    my $text_num = num_by_words($num);

    $self->{text} =
        'Сколь­ко су­ще­ству­ет раз­лич­ных по­сле­до­ва­тель­но­стей из сим­во­лов «плюс» и «минус», ' .
        "дли­ной ровно в $text_num сим­во­лов? ";

    $self->{correct} = 2 ** $num;
    $self->accept_number;
}

sub letter_combinatorics {
    my ($self) = @_;

    my $word_length = rnd->in_range(5, 7);
    my $vowels_count = rnd->in_range(1, 3);
    my $consonants_count = $word_length - $vowels_count;
    my @vowels = rnd->pick_n($vowels_count, @EGE::Russian::vowels);
    my @consonants = rnd->pick_n($consonants_count, @EGE::Russian::consonants);

    my @letters = rnd->shuffle(@vowels, @consonants);

    my $letters = join(', ', @letters);
    $self->{text} =
        "Вася составляет $word_length-буквенные слова, в которых встречаются только буквы $letters, " .
        'причём в каждом слове есть ровно одна гласная буква. Каждая из допустимых согласных букв может встречаться ' .
        'в кодовом слове любое количество раз или не встречаться совсем. Словом считается любая допустимая ' .
        'последовательность букв, не обязательно осмысленная. ' .
        'Сколько существует таких слов, которые может написать Вася?';

    $self->{correct} = $word_length * $vowels_count * $consonants_count ** ($word_length - 1);
    $self->accept_number;
}

sub signal_rockets {
    my ($self) = @_;
    my ($answer, $sequence_length, $colors_count, $repeats_allowed);
    my $order_matters = rnd->coin;
    if ($order_matters) {
        $repeats_allowed = rnd->coin;
        $sequence_length = rnd->in_range(4, 6);
        $colors_count = rnd->in_range(4, 6);
        if ($repeats_allowed) {
            $answer = $colors_count ** $sequence_length;
        } else {
            $colors_count = max $colors_count, $sequence_length;
            $answer = product(($colors_count - $sequence_length + 1) .. $colors_count);
        }
    } else {
        # Формула сочетаний с повторениями неизвестна школьникам.
        $repeats_allowed = 0;
        $sequence_length = rnd->in_range(2, 4);
        $colors_count = rnd->in_range($sequence_length + 1, 6);
        my $s = max $sequence_length, ($colors_count - $sequence_length);
        my $t = min $sequence_length, ($colors_count - $sequence_length);
        $answer = product(($s + 1) .. $colors_count) / product(1..$t);
    }
    my $order_condition_text = $order_matters ? 'существенно' : 'не существенно';
    my $repeats_condition_text = $repeats_allowed ? 'может повторяться' : 'не может повторяться';
    $self->{text} =
        'Для передачи аварийных сигналов договорились использовать специальные цветные сигнальные ракеты, ' .
        'запускаемые последовательно. Одна последовательность ракет – один сигнал; в каком порядке идут ' .
        "цвета – $order_condition_text. Какое количество различных сигналов можно передать при помощи запуска ровно " .
        "${\EGE::NumText::num_by_words($sequence_length, 1, 'genitive')} таких сигнальных ракет, если в ".
        "запасе имеются ракеты ${\EGE::NumText::num_by_words($colors_count, 1, 'genitive')} различных цветов " .
        "(ракет каждого вида неограниченное количество, цвет ракет в последовательности $repeats_condition_text)?";

    $self->{correct} = $answer;
    $self->accept_number;
}

sub how_many_sequences1 {
    my($self) = @_;

    my $first_num = rnd->in_range(1, 3);
    my $second_num = rnd->in_range($first_num + 1, 6);
    my $num_of_letters = rnd->in_range(2, 5);
    my @alphabet = @EGE::Russian::alphabet[0 .. $num_of_letters - 1];

    $self->{text} = sprintf
        'Сколь­ко есть раз­лич­ных сим­воль­ных по­сле­до­ва­тель­но­стей длины от %s до %s ' .
        'в %sбук­вен­ном ал­фа­ви­те {%s}?',
        num_by_words($first_num, 0, 'genitive'),
        num_by_words($second_num, 0, 'genitive'),
        num_by_words($num_of_letters, 0, 'prepositional'),
        join ', ', @alphabet;

    $self->{correct} += $num_of_letters ** $_ for $first_num .. $second_num;
    $self->accept_number;
}

sub how_many_sequences2 {
    my($self) = @_;

    my @word = split '', uc rnd->pick(@EGE::Russian::Animals::distinct_letters);
    my $num = rnd->in_range(3, 7);

    $self->{text} = sprintf
        'Рас­смат­ри­ва­ют­ся сим­воль­ные по­сле­до­ва­тель­но­сти длины %d в %sбук­вен­ном ал­фа­ви­те {%s}. ' .
        'Сколь­ко су­ще­ству­ет таких по­сле­до­ва­тель­но­стей, ' .
        'ко­то­рые на­чи­на­ют­ся с буквы %s и за­кан­чи­ва­ют­ся бук­вой %s?',
        $num, num_by_words(scalar @word, 0, 'prepositional'), join(', ', @word), $word[0], $word[-1];

    $self->{correct} = @word ** ($num - 2);
    $self->accept_number;
}

1;
