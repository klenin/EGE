# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Prog::Field;
use base "EGE::Prog::Var";

use strict;
use warnings;

use overload '""' => sub { $_[0]->{name} },
    'ne' => \&not_equal, 'eq' => \&equal;

sub new {
    my ($class, $attr) = @_;
    my $self;
    if (ref $attr eq 'HASH') {
        $self = $attr;
    } else  {
        $self = {
            name => $attr,
          };
    }
    bless $self, $class;
    $self;
}

sub to_lang {
    my ($self, $lang) = @_;
    $self->{name_alias} ? $self->{name_alias} . '.' . $self->{name} : $self->{name};
}

sub not_equal {
    my ($self, $val) = @_;
    $self->{name} ne $val;
}

sub equal {
    my ($self, $val) = @_;
    $self->{name} eq $val;
}

package EGE::SQL::Table;

use strict;
use warnings;
use EGE::Html;
use EGE::Prog qw(make_expr);
use EGE::Random;

sub new {
    my ($class, $fields, %p) = @_;
    $fields or die;
    @$fields = map ref $_ eq 'EGE::Prog::Field' ? $_ : EGE::Prog::Field->new($_), @$fields;
    my $self = {
        name => $p{name},
        fields => $fields,
        data => [],
        field_index => {},
    };
    my $i = 0;
    $self->{field_index}->{$_} = $i++ for @$fields;
    bless $self, $class;
    $_->{table} = $self for @{$self->{fields}};
    $self;
}

sub name { $_[0]->{name} = $_[1] // $_[0]->{name} }

sub fields { $_[0]->{fields} }

sub find_field {
    my ($self, $field) = @_;
    grep $field eq $_, @{$self->{fields}};
}

sub assign_field_alias {
    my ($self, $alias) = @_;
    $_->{name_alias} = $alias for @{$self->{fields}};
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

sub insert_column {
    my ($self, %p) = @_;
    $p{name} = ref $p{name} eq 'EGE::Prog::Field' ? $p{name} : EGE::Prog::Field->new($p{name});
    $p{name}->{table} = $self;
    splice(@{$self->{fields}}, ($p{index} ? $p{index} : 0), 0, $p{name});
    my $i = 0; my $j = 0;
    splice(@$_, ($p{index} ? $p{index}: 0), 0, $p{array}[$i++]) for @{$self->{data}};
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

    my $result = EGE::SQL::Table->new([ map {ref $_ ne 'EGE::Prog::Field' && ref $_ ?  'expr_' . ++$k : $_ } @$fields ]);

    my @values = map {ref $_  ? $_ : make_expr($_) } @$fields;
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

sub natural_join{
    my ($self, $field) = @_;
    $field->{table}->inner_join($field->{ref_field}->{table}, $field, $field->{ref_field});
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
