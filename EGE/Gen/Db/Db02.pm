# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

package EGE::Gen::Db::Db02;
use base 'EGE::GenBase::MultipleChoice';

use strict;
use warnings;
use utf8;

use EGE::Html;
use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::SQL::Table;
use EGE::SQL::Queries;

sub select_where {
    my ($self) = @_;
    my $rt = EGE::SQL::RandomTable->new(column => 4, row => rnd->in_range(7, 9));
    my $rt_class = $rt->pick;
    my $table = $rt->make;
    my $name_fld = $table->fields->[0];
    my $query = EGE::SQL::Select->new(
        $table, [ $name_fld ],
        EGE::SQL::Utils::generate_nontrivial_cond($table, \&EGE::SQL::Utils::expr_2));
    my $selected = $query->run->column_hash($name_fld);
    $self->{text} = sprintf
        "Имеется таблица <tt>%s</tt>:\n%s\n" .
        'Какие %s в этой таблице удовлетворяют запросу %s?',
        $table->name, $table->table_html,
        $rt_class->get_text_name->{nominative}, $query->text_html_tt;
    $self->variants(my @v = @{$table->column_array($name_fld)});
    $self->{correct} = [ map $selected->{$_} ? 1 : 0, @v ];
}

1;
