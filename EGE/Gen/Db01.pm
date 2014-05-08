# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db01;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::Russian::FamilyNames;
use EGE::Russian::Subjects;
use EGE::SQL::Table;

sub database {
    my ($self) = @_;
    my $table_jobs = EGE::SQL::Table->new([ qw(Профессии Зарплата)]);
    $table_jobs->insert_row($_, rnd->in_range(1000, 10000)) for rnd->pick_n(9, @EGE::Russian::Jobs::list);
    my $cond = '';
    my $count = 0;
    my $select;
    while (1) {
        my $d = rnd->in_range(1000, 10000);
        my $e = EGE::Prog::make_expr(
            [ rnd->pick(ops::comp), 'Зарплата', \$d ],
        );
        $select = $table_jobs->select([], $e);
        $count = $select->count();
        if ($count && $count != $table_jobs->count()) { 
            $cond = html->cdata($e->to_lang_named('SQL'));
            last;
        }
    }
    my $table_text = html->row_n('th', @{$table_jobs->{fields}});
    $table_text .= html->row_n('td', @$_) for @{$table_jobs->{data}};
    $table_text = html->table($table_text, { border => 1 });
    $self->{text} =
        "Заработная плата по профессиям представлена в таблице jobs: \n$table_text\n" .
        "Сколько записей в ней удовлетворяют запросу SELECT * FROM jobs WHERE $cond?\n",
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $table_jobs->count()));
}

1;