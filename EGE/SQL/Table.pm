# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::SQL::Table;

use strict;
use warnings;
use EGE::Html;
use EGE::Prog qw(make_expr);
use EGE::Random;

sub new {
    my ($class, $fields, %p) = @_;
    $fields or die;
    my $self = {
        name => $p{name},
        fields => $fields,
        data => [],
        field_index => {},
    };
    my $i = 0;
    $self->{field_index}->{$_} = $i++ for @$fields;
    bless $self, $class;
    $self;
}

sub name { $_[0]->{name} = $_[1] // $_[0]->{name} }

sub fields { $_[0]->{fields} }

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

sub insert_column {
    my ($self, %p) = @_;
    unshift @{$self->{fields}}, $p{name};
    my $i = 0; my $j = 0;
    unshift @$_, $p{array}[$i++] for @{$self->{data}};
    $self->{field_index}->{$_} = $j++ for @{$self->{fields}};
    $self;
 }

sub print_row { print join("\t", @{$_[0]}), "\n"; }

sub print {
    my $self = shift;
    print_row $_ for $self->{fields}, @{$self->{data}};
}

sub count { @{$_[0]->{data}}; }

sub _row_hash {
    my ($self, $row) = @_;
    +{ map { +$_ => $row->[$self->{field_index}->{$_}] } @{$self->{fields}} };
}

sub select {
    my ($self, $fields, $where, $ref) = @_;

    my $k = 0;
    my $result = EGE::SQL::Table->new([ map ref $_ ? 'expr_' . ++$k : $_, @$fields ]);

    my @values = map ref $_ ? $_ : make_expr($_), @$fields;
    my $calc_row = sub { map $_->run($_[0]), @values };

    my $tab_where = $self->where($where, $ref);
    $result->{data} = [ map [ $calc_row->($self->_row_hash($_)) ], @{$tab_where->{data}} ];
    $result;
}

sub where {
    my ($self, $where, $ref) = @_;
    $where or return $self;
    my $table = EGE::SQL::Table->new($self->{fields});
    for my $data (@{$self->{data}}) {
        push @{$table->{data}}, $ref ? $data : [ @$data ] if $where->run($self->_row_hash($data));
    }
    $table;
}

sub update {
    my ($self, $assigns, $where) = @_;
    my @data = $where ? @{$self->where($where, 1)->{data}} : @{$self->{data}};
    for my $row (@data) {
        my $hash = $self->_row_hash($row);
        $assigns->run($hash);
        $row->[$self->{field_index}->{$_}] = $hash->{$_} for @{$self->{fields}};
    }
    $self;
}

sub delete {
    my ($self, $where) = @_;
    $self->{data} = $self->select( [ @{$self->{fields}} ], make_expr(['!', $where]), 1)->{data};
    $self;
}

sub inner_join {
    my ($table1, $table2, $field1, $field2) = @_;
    my $result = EGE::SQL::Table->new([ @{$table1->{fields}}, @{$table2->{fields}} ]);
    my $index1 = $table1->{field_index}->{$field1} // die("Unknown field $field1");
    my $index2 = $table2->{field_index}->{$field2} // die("Unknown field $field2");
    my %h;
    push @{$h{$_->[$index2]}}, $_ for @{$table2->{data}};
    for my $row1 (@{$table1->{data}}) {
        my $rows2 = $h{$row1->[$index1]} or next;
        $result->insert_row(@$row1, @$_) for @$rows2;
    }
    $result;
}

sub table_html {
    my ($self) = @_;
    my $table_text = html->row_n('th', @{$self->{fields}});
    $table_text .= html->row_n('td', @$_) for @{$self->{data}};
    $table_text = html->table($table_text, { border => 1 });
}

sub fetch_val {
   my ($self, $field) = @_;
   rnd->pick(@{rnd->pick($self->column_array($field))}) + rnd->pick(0, -50, 50);
}

sub random_row { rnd->pick(@{$_[0]->{data}}) }

sub column_array {
    my ($self, $field) = @_;
    my $column = $self->{field_index}->{$field} // die $field;
    [ map $_->[$column], @{$self->{data}} ];
}

1;
