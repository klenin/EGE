# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Prog::Field;
use base 'EGE::Prog::Var';

use strict;
use warnings;

use overload
    '""' => sub { $_[0]->{name} }, 'cmp' => sub { $_[0]->{name} cmp $_[1] };

sub new {
    my ($class, $attr) = @_;
    my $self = ref $attr eq 'HASH' ? $attr : { name => $attr };
    bless $self, $class;
}

sub to_lang {
    my ($self, $lang) = @_;
    $self->{name_alias} ? $self->{name_alias} . '.' . $self->{name} : $self->{name};
}

package EGE::SQL::Table;

use strict;
use warnings;
use EGE::Html;
use EGE::Prog qw(make_expr);
use EGE::Random;

sub new {
    my ($class, $fields, %p) = @_;
    $fields or die 'No fields';
    $fields = [ map _make_field($_), @$fields ];
    my $self = {
        name => $p{name},
        fields => $fields,
        data => [],
        field_index => {},
    };
    _update_field_index($self);
    $_->{table} = $self for @$fields;
    bless $self, $class;
}

sub _make_field { $_[0]->isa('EGE::Prog::Field') ? $_[0] : EGE::Prog::Field->new($_[0]) }

sub _update_field_index {
    my $i = 0;
    $_[0]->{field_index}->{$_} = $i++ for @{$_[0]->{fields}};
}

sub name { $_[0]->{name} = $_[1] // $_[0]->{name} }

sub fields { $_[0]->{fields} }

sub find_field {
    my ($self, $field) = @_;
    my $i = $self->{field_index}->{$field};
    defined $i ? $self->{fields}->[$i] : undef;
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
    my $field = _make_field($p{name});
    $field->{table} = $self;
    $p{index} ||= 0;
    splice(@{$self->{fields}}, $p{index}, 0, $field);
    my $i = 0;
    splice(@$_, $p{index}, 0, $p{array}[$i++]) for @{$self->{data}};
    $self->_update_field_index;
    $self;
}

sub print_row { print join("\t", @{$_[0]}), "\n"; }

sub print {
    my $self = shift;
    print_row $_ for $self->{fields}, @{$self->{data}};
}

sub count { @{$_[0]->{data}} }

sub _row_hash {
    my ($self, $row, $env) = @_;
    $env->{$_} = $row->[$self->{field_index}->{$_}] for @{$self->{fields}};
    $env;
}
sub _hash {
    my ($self) = @_;
    my $env = {};
    $env->{'&columns'} =  +{ map { $_ => $self->column_array($_) } @{$self->{fields}} };
    $env->{'&'} = +{ map { $_ => 'EGE::SQL::Table::Aggregate::' . $_ } EGE::Utils::aggregate_function };
    $env->{'&count'} = $self->count;
    $env;
}

sub select {
    my ($self, $fields, $where, $p) = @_;
    my ($ref, $aggr, $group) = 0;
    if (ref $p eq 'HASH') {
        $ref = $p->{ref};
    }
    $aggr =  ref $_ eq 'EGE::Prog::CallFuncAggregate' ? 1: $aggr for @$fields;
    my $k = 0;

    my $result = EGE::SQL::Table->new([ map { ref $_ ne 'EGE::Prog::Field' && ref $_ ? 'expr_' . ++$k : $_ } @$fields ]);

    my @values = map { ref $_  ? $_ : make_expr($_) } @$fields;
    my $calc_row = sub { map $_->run($_[0]), @values };

    my $tab_where = $self->where($where, $ref);
        my @ans;
        my $evn = $tab_where->_hash;
        push @ans, [ $calc_row->($tab_where->_row_hash($_, $evn)) ] for @{$tab_where->{data}};
        $result->{data} = $aggr ? [ $ans[0] ] : [ @ans ];
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

sub natural_join {
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

package EGE::SQL::Table::Aggregate::count;
use strict;
use warnings;
use EGE::Prog qw(make_expr);

sub call {
    my ($self, $params, $env, $id) = @_;
    my $val = @$params[0];
    $env->{'count_field'} = $env->{'count_field'} ? $env->{'count_field'} : {};
    if (!$env->{'count_field'}->{$val}) {
        $env->{$id}->{count} = $env->{$id}->{count} ? $env->{$id}->{count} + 1 : 1;
    }
    $env->{'count_field'}->{$val} = 1;
    $env->{$id}->{count};
}

package EGE::SQL::Table::Aggregate::sum;
use strict;
use warnings;

sub call {
    my ($self, $params, $env, $id) = @_;
    my $val = @$params[0];
    $env->{$id}->{sum} += $val;
}

package EGE::SQL::Table::Aggregate::avg;
use strict;
use warnings;

sub call {
    my ($self, $params, $env, $id) = @_;
    my $val = @$params[0];
    $env->{$id}->{sum} += $val;
    $env->{$id}->{count}++;
    $env->{$id}->{sum} / $env->{$id}->{count};
}

package EGE::SQL::Table::Aggregate::min;
use strict;
use warnings;

sub call {
    my ($self, $params, $env, $id) = @_;
    $env->{$id}->{min} = @$params[0] if (!defined $env->{$id}->{min});
    $env->{$id}->{min} = @$params[0] < $env->{$id}->{min} ? @$params[0] : $env->{$id}->{min};
}

package EGE::SQL::Table::Aggregate::max;
use strict;
use warnings;

sub call {
    my ($self, $params, $env, $id) = @_;
    $env->{$id}->{max} = @$params[0] if (!defined $env->{$id}->{max});
    $env->{$id}->{max} = @$params[0] > $env->{$id}->{max} ? @$params[0] : $env->{$id}->{max};
}

1;
