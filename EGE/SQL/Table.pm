# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::SQL::Table;

use strict;
use warnings;
use EGE::Html;

sub new {
    my ($class, $fields) = @_;
    $fields or die;
    my $self = {
        fields => $fields,
        data => [],
        field_index => {},
    };
    my $i = 0;
    $self->{field_index}->{$_} = $i++ for @$fields;
    bless $self, $class;
    $self;
}

sub insert_row {
    my $self = shift;
    @_ == @{$self->{fields}}
        or die sprintf "Wrong column count %d != %d", scalar @_, scalar @{$self->{fields}};
    push @{$self->{data}}, [ @_ ];
    $self;
}

sub insert_rows {
    my $self = shift;
    $self->insert_row(@$_) for @_;
    $self;
}

sub print_row { print join("\t", @{$_[0]}), "\n"; }

sub print {
    my $self = shift;
    print_row $_ for $self->{fields}, @{$self->{data}};
}
sub count {
    @{$_[0]->{data}};
}

sub select {
    my ($self, $fields, $where, $ref) = @_;
    my $tab_where = $self->where($where, $ref);
    my $result = EGE::SQL::Table->new($fields);
    my @indexes = map $tab_where->{field_index}->{$_} // die("Unknown field $_"), @$fields;
    $result->{data} = [ map [ @$_[@indexes] ], @{$tab_where->{data}} ];
    $result;
}


sub where {
    my ($self, $where, $ref) = @_;
    $where or return $self;
    my $table = EGE::SQL::Table->new($self->{fields});
    for my $data (@{$self->{data}}) {
        my $hash = {};
        $hash->{$_} = @$data[$self->{field_index}->{$_}] for @{$self->{fields}};
        push @{$table->{data}}, $ref ? $data : [ @$data ] if $where->run($hash);
    }
    $table;
}

sub update {
    my ($self, $fields, $exp, $where) = @_;
    my @data = $where ? @{$self->where($where, 1)->{data}} : @{$self->{data}};
    my @indexes = map $self->{field_index}->{$_} // die("Unknown field $_"), @$fields;
    @$_[@indexes] = $exp->(@$_) for @data;
    $self;
}

sub table_html { 
    my ($self) = @_;
    my $table_text = html->row_n('th', @{$self->{fields}});
    $table_text .= html->row_n('td', @$_) for @{$self->{data}}; 
    $table_text = html->table($table_text, { border => 1 });
}

1;
