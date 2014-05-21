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
    my ($class, $table, $name, $fields, $where) = @_;
    $fields or die;
    my $self = {
        table => $table,
        table_name => $name,
        fields => $fields,
        where => $where,
    };
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
    "SELECT $fields FROM $self->{table_name}" . $self->where_sql;
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
1
