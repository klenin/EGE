# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::SQL::Select;

use strict;
use warnings;
use EGE::Html;
use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;

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
    my $where = $self->{where} ? ' WHERE '. $self->{where}->to_lang_named('SQL') : '';
    "SELECT $fields FROM $self->{table_name}$where";
}

sub text_html { html->tag('tt', html->cdata($_[0]->text)); }

package EGE::SQL::Update;

use strict;
use warnings;
use EGE::Html;

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
    my $where = $self->{where} ? ' WHERE '. $self->{where}->to_lang_named('SQL') : '';
    "UPDATE $self->{table_name} SET $assigns$where";
}

sub text_html { html->tag('tt', html->cdata($_[0]->text)); }

package EGE::SQL::Delete;

use strict;
use warnings;
use EGE::Html;

sub new { 
    my ($class, $table, $name, $where) = @_;
    my $self = {
        table => $table,
        where => $where,
        table_name => $name,
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
    my $ans = "<tt>DELETE FROM ".$self->{table_name}." WHERE ";
    $ans .=  html->cdata($self->{where}->to_lang_named('SQL'));
    $ans .="</tt>";
}

1