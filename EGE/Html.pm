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
    $self->open_tag($tag, $attrs, defined $body ? ">$body</$tag>" : '/>');
}

sub attrs_str { join('', map qq~ $_="$_[1]->{$_}"~, sort keys %{$_[1]}) }

sub open_tag {
    my ($self, $tag, $attrs, $rest) = @_;
    $attrs ||= {};
    "<$tag" . $self->attrs_str($attrs) . ($rest || '>');
}

sub close_tag {
    my ($self, $tag) = @_;
    "</$tag>";
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

sub pre {
    my ($self, $data, $attr) = @_;
    $self->tag('pre', $self->cdata($data), $attr);
 }

sub style {
    my ($self, %p) = @_;
    style => join ' ', map "$_: $p{$_};", sort keys %p;
}

sub div_xy {
    my ($self, $text, $x, $y, $p) = @_;
    $self->div($text, { $self->style(width => "${x}px", height => "${y}px", %$p) });
}

sub nbsp { ' ' }

BEGIN {
    for my $tag (qw(p td th table div ol ul li)) {
        no strict 'refs';
        *$tag = sub {
            my $self = shift;
            $self->tag($tag, @_);
        };
    }
}

1;

