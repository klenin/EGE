# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::SQL::Query;

use strict;
use warnings;
use EGE::Html;

sub text_html { html->tag('tt', html->cdata($_[0]->text)); }
sub where_sql { $_[0]->{where} ? ' WHERE '. $_[0]->{where}->to_lang_named('SQL') : '' };

package EGE::SQL::Select;
use base 'EGE::SQL::Query';

sub new { 
    my ($class, $table, $name, $fields, $where, $inner) = @_;
    $fields or die;
    my $self = {
        table => $table,
        table_name => $name,
        inner_join => $inner,
        fields => $fields,
        where => $where,
    };
    if (ref($where) eq "EGE::SQL::Inner_join") {
        $self->{inner_join} = $where;
        $self->{where} = $inner;
    }
    bless $self, $class;
    $self;
}

sub run {
    my ($self) = @_;
    $self->{table}->select($self->{fields}, $self->{where});
}

sub _field_sql { ref $_ ? $_->to_lang_named('SQL') : $_ }

sub text {
    my ($self) = @_;
    my $fields = join(', ', map &_field_sql, @{$self->{fields}}) || '*';
    my $table  =  $self->{inner_join} ? $self->{inner_join}->text : $self->{table_name};
    "SELECT $fields FROM $table" . $self->where_sql;
}

package EGE::SQL::Update;
use base 'EGE::SQL::Query';

sub new { 
    my ($class, $table, $name, $assigns, $where) = @_;
    $assigns or die;
    my $self = {
        table => $table,
        table_name => $name,
        assigns => $assigns,
        where => $where,
    };
    bless $self, $class;
    $self;
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
    my ($class, $table, $name, $where) = @_;
    my $self = {
        table => $table,
        table_name => $name,
        where => $where,
    };
    bless $self, $class;
    $self;
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
    my ($class, $table, $name, $value) = @_;
    my $self = {
        table => $table,
        table_name => $name,
        value => $value,
    };
    bless $self, $class;
    $self;
}
sub run {
    my ($self) = @_;
    $self->{table}->insert_row (@{$self->{value}});
}

sub text {
    my ($self) = @_;
    my $fields = join(', ', @{$self->{table}->{fields}});
    my $val = join("', '", @{$self->{value}});
    "INSERT INTO $self->{table_name} ( $fields ) VALUES ( '$val' )";
}

package EGE::SQL::Inner_join;
use base 'EGE::SQL::Query';

sub new { 
    my ($class, $name1, $name2, $tab1, $tab2, $field1, $field2) = @_;
    my $self = {
        tab1 => $tab1,
        tab2 => $tab2,
        field1 => $field1,
        field2 => $field2,
        table_name1 => $name1,
        table_name2 => $name2,
    };
    bless $self, $class;
    $self;
}

sub run {
    my ($self) = @_;
    $self->{tab1}->inner_join($self->{tab2}, $self->{field1}, $self->{field2});
}

sub text {
    my ($self) = @_;
    "$self->{table_name1} INNER JOIN $self->{table_name2} ON " .
        "$self->{table_name1}.$self->{field1} = $self->{table_name2}.$self->{field2}";
}

1
