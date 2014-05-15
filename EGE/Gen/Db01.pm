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
use EGE::Russian::Jobs;
use EGE::SQL::Table;
use EGE::Utils;

sub trivial_select {
    my ($self) = @_;
    my $table_jobs = EGE::SQL::Table->new([ qw(Профессия Зарплата) ]);
    my @jobs = rnd->pick_n(9, @EGE::Russian::Jobs::list);
    my @values = map rnd->in_range(10, 90) * 100, @jobs;
    $table_jobs->insert_rows(@{EGE::Utils::transpose(\@jobs, \@values)});
    my ($cond, $count);
    do {
        my $d = rnd->pick(@values) + rnd->pick(0, -50, 50);
        $cond = EGE::Prog::make_expr([ rnd->pick(ops::comp), 'Зарплата', \$d ]);
        $count = $table_jobs->select([], $cond)->count();
    } until (1 < $count && $count < $table_jobs->count());
    my $cond_text = html->cdata($cond->to_lang_named('SQL'));
    $self->{text} =
        "Заработная плата по профессиям представлена в таблице <tt>jobs</tt>: \n".$table_jobs->table_html()."\n" .
        "Сколько записей в ней удовлетворяют запросу <tt>SELECT * FROM jobs WHERE $cond_text</tt>?",
    $self->variants($count, rnd->pick_n(3, grep $_ != $count, 1 .. $table_jobs->count()));
}

1;
