# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Svg;

use strict;
use warnings;
use utf8;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(svg);

use EGE::Html;

my $svg;

sub svg {
    $svg ||= EGE::Svg->new;
}

sub new {
    my $self = {};
    bless $self, shift;
    $self;
}

sub start {
    my ($self, $viewBox) = @_;
    html->open_tag('svg', {
        xmlns => 'http://www.w3.org/2000/svg',
        varsion => '1.1',
        viewBox => join(' ', @$viewBox),
        preserveAspectRatio => 'meet'
    });
}

sub text {
    my ($self, $text, %params) = @_;
    html->tag('text', $text, \%params) . "\n";
}

sub end { "</svg>\n"; }

BEGIN {
    for my $tag (qw(line circle)) {
        no strict 'refs';
        *$tag = sub {
            my ($self, %params) = @_;
            html->tag($tag, undef, \%params) . "\n";
        };
    }
}

1;
