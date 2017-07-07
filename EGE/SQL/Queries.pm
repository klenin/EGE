# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::SQL::Query;

use strict;
use warnings;
use EGE::Html;

sub text_html { $_[0]->text({ html => 1 }) }
sub text_html_tt { html->tag('tt', $_[0]->text({ html => 1 })) }

sub _field_list_sql {
    my ($self, $fields, $opts) = @_;
    join ', ', map ref $_ ? $_->to_lang_named('SQL', $opts) : $_, @$fields;
}

sub where_sql {
    my ($self, $opts) = @_;
    $self->{where} ? 'WHERE '. $self->{where}->to_lang_named('SQL', $opts) : ''
}

sub having_sql {
    my ($self, $opts) = @_;
    $self->{having} ? 'HAVING '. $self->{having}->to_lang_named('SQL', $opts) : '';
}

sub group_by_sql {
    my ($self, $opts) = @_;
    $self->{group} ? 'GROUP BY '. $self->_field_list_sql($self->{group}) : ''
}

sub _maybe_run { $_[1]->can('run') ? $_[1]->run : $_[1]; }

sub init_table {
    my ($self, $table) = @_;
    $table || die 'No table';
    $self->{table} = ref $table ? $table : undef;
    $self->{table_name} = ref $table ? $table->name : $table;
    $self;
}

package EGE::SQL::Select;
use base 'EGE::SQL::Query';

sub new {
    my ($class, $table, $fields, $where, %p) = @_;
    $fields or die;
    @$fields = map ref $_ ? $_ : EGE::Prog::Field->new($_), @$fields;
    my $self = {
        fields => $fields,
        where => $where,
        group => $p{group},
        having => $p{having},
    };
    bless $self, $class;
    $self->init_table($table);
}

sub run {
    my ($self) = @_;
    my $table = $self->{table}->can('run') ? $self->{table}->run : $self->{table};
    $table->select($self->{fields}, $self->{where}, { group => $self->{group}, having => $self->{having} });
}

sub name { $_[0]->{table_name} }


sub text {
    my ($self, $opts) = @_;
    my $fields = $self->_field_list_sql($self->{fields}, $opts) || '*';
    my $t = $self->{table};
    my $table_text = $t && $t->can('text') ? $t->text($opts) : $self->{table_name};
    join ' ',
        "SELECT $fields FROM $table_text",
        map $self->$_($opts) || (), qw(where_sql group_by_sql having_sql);
}

package EGE::SQL::SubqueryAlias;
use base 'EGE::SQL::Query';

sub name { $_[0]->{alias} }

sub new {
    my ($class, $table, $alias) = @_;
    $table && $alias or die;
    my $self = {
        alias => $alias,
    };
    bless $self, $class;
    $self->init_table($table);
}

sub run {
    my ($self) = @_;
    $self->_maybe_run($self->{table});
}

sub text {
    my ($self, $opts) = @_;
    my $q = $self->{table} && $self->{table}->can('text') ?
        '(' . $self->{table}->text($opts) . ") AS" : $self->{table_name};
    "$q $self->{alias}";
}

package EGE::SQL::Update;
use base 'EGE::SQL::Query';

sub new {
    my ($class, $table, $assigns, $where) = @_;
    $assigns or die;
    my $self = {
        assigns => $assigns,
        where => $where,
    };
    bless $self, $class;
    $self->init_table($table);
}

sub run {
    my ($self) = @_;
    $self->{table}->update($self->{assigns}, $self->{where});
}

sub text {
    my ($self, $opts) = @_;
    my $assigns = $self->{assigns}->to_lang_named('SQL');
    join ' ', "UPDATE $self->{table_name} SET $assigns", $self->where_sql($opts) || ();
}

package EGE::SQL::Delete;
use base 'EGE::SQL::Query';

sub new {
    my ($class, $table, $where) = @_;
    my $self = {
        where => $where,
    };
    bless $self, $class;
    $self->init_table($table);
}

sub run {
    my ($self) = @_;
    $self->{table}->delete($self->{where});
}

sub text {
    my ($self, $opts) = @_;
    join ' ', "DELETE FROM $self->{table_name}", $self->where_sql($opts) || ();
}

package EGE::SQL::Insert;
use base 'EGE::SQL::Query';

sub new {
    my ($class, $table, $values) = @_;
    my $self = {
        values => $values,
    };
    bless $self, $class;
    $self->init_table($table);
    !$self->{table} || @{$self->{table}->{fields}} == @{$self->{values}}
        or die 'Field count != value count';
    $self;
}

sub run {
    my ($self) = @_;
    $self->{table}->insert_row(@{$self->{values}});
}

sub text {
    my ($self, $opts) = @_;
    my $fields = join ', ', @{$self->{table}->{fields}};
    my $values = join ', ', map /^\d+$/ ? $_ : "'$_'", @{$self->{values}};
    "INSERT INTO $self->{table_name} ($fields) VALUES ($values)";
}

package EGE::SQL::InnerJoin;
use base 'EGE::SQL::Query';

sub new {
    my ($class, @tables) = @_;
    @tables == 2 or die;
    my $self = {
        tables => \@tables,
    };
    bless $self, $class;
    $self;
}

sub name { return ref $_ ? $_->name : $_ for $_[0]->{tables}->[0]->{tab} }

sub tables { @{$_[0]->{tables}} }

sub run {
    my ($self) = @_;
    my ($t1, $t2) = map $self->_maybe_run($_->{tab}), $self->tables;
    $t1->inner_join($t2, map $_->{field}, $self->tables);
}

sub text {
    my ($self, $opts) = @_;
    my ($t1, $t2) = map
        !ref $_->{tab} ? $_->{tab} :
        $_->{tab}->can('text') ? $_->{tab}->text :
        $_->{tab}->{name},
        $self->tables;
    my ($f1, $f2) = map {
        $_->{field} =~ /\./ ? $_->{field} :
        (ref $_->{tab} ? $_->{tab}->name : $_->{tab}) . ".$_->{field}"
    } $self->tables;
    "$t1 INNER JOIN $t2 ON " .
        ($self->{where} ? $self->{where}->to_lang_named('SQL', $opts) : "$f1 = $f2");
}

package EGE::SQL::InnerJoinExpr;
use base 'EGE::SQL::InnerJoin';

sub new {
    my ($class, $where, @tables) = @_;
    my $self = {
        tables => \@tables,
        where => $where,
    };
    bless $self, $class;
    $self;
}

sub run {
    my ($self) = @_;
    my ($t1, $t2) = map $self->_maybe_run($_->{tab}), $self->tables;
    $t1->inner_join_expr($t2, $self->{where});
}

1;
