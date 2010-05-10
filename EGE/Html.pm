# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Html;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(html);

my $html;

sub html {
    $html ||= EGE::Html->new;
}

sub new {
    my $self = {};
    bless $self, shift;
    $self;
}

sub tag {
    my ($self, $tag, $body, $attrs) = @_;
    $attrs ||= {};
    "<$tag" . join('', map qq~ $_="$attrs->{$_}"~, keys %$attrs) .
    (defined $body ? ">$body</$tag>" : '/>');
}

sub tr_ {
    my $self = shift;
    $self->tag('tr', @_);
}

sub row {
    my ($self, $tag, @data) = @_;
    $self->tr_(join '', map $self->tag($tag, $_), @data);
}

sub row_n { row(@_) . "\n" }

sub cdata { "<![CDATA[$_[1]]]>" }

BEGIN {
    for my $tag (qw(td th table)) {
        no strict 'refs';
        *$tag = sub {
            my $self = shift;
            $self->tag($tag, @_);
        };
    }
}

1;

