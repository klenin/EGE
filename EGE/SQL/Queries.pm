# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::SQL::Query;

use strict;
use warnings;
use EGE::Html;

sub text_html { html->tag('tt', html->cdata($_[0]->text)); }
sub where_sql { $_[0]->{where} ? ' WHERE '. $_[0]->{where}->to_lang_named('SQL') : '' }

sub init_table {
    my ($self, $table) = @_;
    $self->{table} = ref $table ? $table : undef;
    $self->{table_name} = ref $table ? $table->name : $table;
    $self;
}

package EGE::SQL::Select;
use base 'EGE::SQL::Query';

sub new {
    my ($class, $table, $fields, $where, %h) = @_;
    $fields or die;
    my $self = {
        fields => $fields,
        where => $where,
        as => $h{as},
    };
    bless $self, $class;
    $self->init_table($table);
}

sub run {
    my ($self) = @_;
    my $table = $self->{table}->can('run') ? $self->{table}->run : $self->{table};
    $table->select($self->{fields}, $self->{where});
}

sub name {
    my ($self) = @_;
    $self->{as} ? $self->{as}: '';
}

sub _field_sql { ref $_ ? $_->to_lang_named('SQL') : $_ }

sub text {
    my ($self) = @_;
    my $fields = join(', ', map &_field_sql, @{$self->{fields}}) || '*';
    my $table = $self->{table_name};
    $table = $self->{table}->can('text') ? $self->{table}->text : $self->{table_name} if $self->{table};
    $table = '(' . $table . ') AS ' . $self->{table_name} if ref $self->{table} eq qw(EGE::SQL::Select);
    "SELECT $fields FROM $table" . $self->where_sql;
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
    $self->{table}->update($self->{fields}, $self->{assigns}, $self->{where});
}

sub text {
    my ($self) = @_;
    my $assigns = $self->{assigns}->to_lang_named('SQL');
    "UPDATE $self->{table_name} SET $assigns" . $self->where_sql;
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
    my ($self) = @_;
    "DELETE FROM $self->{table_name}" . $self->where_sql;
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
    my ($self) = @_;
    my $fields = join ', ', @{$self->{table}->{fields}};
    my $values = join ', ', map /^\d+$/ ? $_ : "'$_'", @{$self->{values}};
    "INSERT INTO $self->{table_name} ($fields) VALUES ($values)";
}

package EGE::SQL::Inner_join;
use base 'EGE::SQL::Query';

sub new { 
    my ($class, $table1, $table2, %h) = @_;
    my $self = {
        table1 => $table1,
        table2 => $table2,
        as => $h{as},
    };
    bless $self, $class;
    $self;
}

sub name {
    my ($self, $table) = @_;
    ref $table ? $table->name : $table;
}

sub run {
    my ($self) = @_;
    my $tab1 = ${$self->{table1}}{tab}->can('run') ? ${$self->{table1}}{tab}->run : ${$self->{table1}}{tab};
    my $tab2 = ${$self->{table2}}{tab}->can('run') ? ${$self->{table2}}{tab}->run : ${$self->{table2}}{tab};
    $tab1->inner_join($tab2, ${$self->{table1}}{field}, ${$self->{table2}}{field});
}
sub _name_table {
    my ($self, $table) = @_;
    my $name = $self->name($$table{tab});
    $name = $$table{as} if $$table{as};
    $name = $$table{name} if $$table{name};
    my $tab = $$table{tab}->can('text') ? $$table{tab}->text : $$table{tab}->name;
    if (ref $$table{tab} eq 'EGE::SQL::Select') {
        $tab = '(' . $tab . ') AS ' . $name;
    }
    $tab .= " $name" if $$table{as};
    $name, $tab;
}

sub text {
    my ($self) = @_;
    my ($name1, $tab1) = $self->_name_table($self->{table1});
    my ($name2, $tab2) = $self->_name_table($self->{table2});
    "$tab1 INNER JOIN $tab2 ON " .
        "$name1.${$self->{table1}}{field} = $name2.${$self->{table2}}{field}";
}

1;
