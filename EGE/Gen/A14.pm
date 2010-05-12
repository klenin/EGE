# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::A14;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::Russian::FamilyNames;

sub database {
    my ($self) = @_;
    my @families = rnd->pick_n_sorted(6, @EGE::Russian::FamilyNames::list);
    my @subjects = qw(Математика История Физика Химия Биология);
    my @table;
    for (@families) {
        my $sex = rnd->coin;
        push @table, [
            $_ . ($sex ? '' : 'а'), ($sex ? 'м' : 'ж'),
            map rnd->in_range(50, 90), @subjects
        ];
    }

    my $table_text = html->row_n('th', qw(Фамилия Пол), @subjects);
    $table_text .= html->row_n('td', @$_) for @table;
    $table_text = html->table($table_text, { border => 1 });

    my $cond = '';
    my $count = 0;
    while (1) {
        my ($s1, $s2) = rnd->pick_n(2, 0 .. @subjects - 1);
        my $sex = rnd->coin ? 1 : 0;
        my $e = EGE::Prog::make_expr([
            rnd->pick('&&', '||'),
            [ '==', 'Пол', \$sex ],
            [ rnd->pick(ops::comp), @subjects[$s1, $s2] ],
        ]);
        $count = 0;
        for my $r (@table) {
            my $vars = { 'Пол' => $r->[1] eq 'м' ? 1 : 0 };
            $vars->{$subjects[$_]} = $r->[2 + $_] for $s1, $s2;
            ++$count if $e->run($vars);
        }
        if ($count && $count < @table - 1) {
            $sex = $sex ? q~'м'~ : q~'ж'~;
            $cond = html->cdata($e->to_lang_named('Alg'));
            last;
        }
    }

    $self->{text} =
        "Результаты тестирования представлены в таблице\n$table_text\n" .
        "Сколько записей в ней удовлетворяют условию «$cond»?",
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. @table));
}

1;
