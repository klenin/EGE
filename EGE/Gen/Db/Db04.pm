# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::Db::Db04;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Html;
use EGE::Prog qw(make_expr make_block);
use EGE::Prog::Lang;
use EGE::Random;
use EGE::SQL::Queries;
use EGE::SQL::RandomTable;
use EGE::SQL::Table;
use EGE::Utils qw(tail);

sub random_cond {
    my ($f1, $f2, $f3) = rnd->shuffle(@_);
    make_expr([
        rnd->pick('&&', '||'),
        [ rnd->pick(ops::comp), $f1, $f2 ],
        [ rnd->pick(ops::comp), $f3, $f2 ],
    ]);
}

sub choose_update {
    my ($self) = @_;
    my $rt = EGE::SQL::RandomTable->new(column => rnd->in_range(4, 5), row => rnd->in_range(5, 7));
    my $rt_class = $rt->pick;
    my $table = $rt->make;
    my $old_table_text = $table->table_html;
    my @fields = tail @{$table->fields};
    my $f1 = rnd->pick(@fields);
    my %used = (0 => 1);
    my @requests;
    my $iter = 0;
    while (@requests < 3 && ++$iter < 50) {
        my $cond = random_cond(rnd->pick_n(3, @fields));
        my $count = $table->count_where($cond);
        next if $used{$count}++;
        push @requests, EGE::SQL::Update->new($table,
            make_block([ '=', $f1, rnd->pick_except($f1, @fields) ]), $cond);
    }
    push @requests, map EGE::SQL::Update->new($table,
        make_block([ '=', rnd->pick_except($f1, @fields), $f1 ]), $requests[$_]->{where}), 0..1;
    $requests[0]->run;
    $self->{text} = sprintf
        "В таблице <tt>%s</tt> представлен список %s<br/>до выполнения запроса: \n%s\n" .
        "после выполнения запроса: \n%s\n" .
        'Какой запрос надо выполнить, чтобы из первой таблицы получить вторую?',
        $table->name, $rt_class->get_text_name->{genitive},
        $old_table_text, $table->table_html;
    $self->variants(map $_->text_html_tt, @requests);
}

1;
