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
    $body = join '', @$body if ref $body eq 'ARRAY';
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

sub _underscores {
    my ($k) = @_;
    $k =~ tr/_/-/;
    $k;
}

sub style {
    my ($self, %p) = @_;
    style => join ' ', map _underscores($_) . ": $p{$_};", sort keys %p;
}

sub div_xy {
    my ($self, $text, $x, $y, $p) = @_;
    $self->div($text, { $self->style(width => "${x}px", height => "${y}px", %$p) });
}

sub nbsp { ' ' }

sub tag2 {
    my ($self, $tag1, $tag2, $body, $attrs1, $attrs2) = @_;
    $self->tag($tag1, [ map $self->tag($tag2, $_, $attrs2), @$body ], $attrs1);
}

sub ul_li {
    my ($self, @rest) = @_;
    $self->tag2('ul', 'li', @rest);
}

sub ol_li {
    my ($self, @rest) = @_;
    $self->tag2('ol', 'li', @rest);
}

BEGIN {
    for my $tag (qw(p td th table div ol ul li code)) {
        no strict 'refs';
        *$tag = sub {
            my $self = shift;
            $self->tag($tag, @_);
        };
    }
}

1;

