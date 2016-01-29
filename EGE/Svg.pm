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
        version => '1.1',
        viewBox => join(' ', @$viewBox),
        preserveAspectRatio => 'none meet'
    }) . "\n";
}

sub end { "</svg>\n"; }

BEGIN {
    no strict 'refs';
    for my $tag (qw(line circle rect path)) {
        *$tag = sub {
            my ($self, %params) = @_;
            html->tag($tag, undef, \%params) . "\n";
        };
    }
    for my $tag (qw(text tspan g pattern marker defs)) {
        *$tag = sub {
            my ($self, $text, %params) = @_;
            $text = join '', @$text if ref $text eq 'ARRAY';
            html->tag($tag, $text, \%params) . "\n";
        };
    }
}

1;
