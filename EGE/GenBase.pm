# Copyright © 2010 Alexander S. Klenin
# Copyright © 2013 Natalia D. Zemlyannikova
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

use strict;
use warnings;

package EGE::GenBase;

use Carp;

sub new {
    my ($class, %init) = @_;
    my $self = { text => undef, correct => undef };
    bless $self, $class;
    $self->init;
    $self;
}

sub post_process {}

package EGE::GenBase::SingleChoice;
use base 'EGE::GenBase';

use EGE::Random;

sub init {
    $_[0]->{type} = 'sc';
    $_[0]->{correct} = 0;
}

sub variants {
    my $self = shift;
    $self->{variants} = [ @_ ];
}

sub formated_variants {
    my ($self, $format) = (shift, shift);
    $self->variants(map { sprintf $format, $_ } @_);
}

sub check_distinct_variants {
    my ($self)= @_;
    my $v = $self->{variants} or die;
    my %h;
    @h{@$v} = undef;
    keys %h == @$v or Carp::confess join ', ', @$v;
}

sub shuffle_variants {
    my ($self)= @_;
    $self->{variants} or die;
    my @order = rnd->shuffle(0 .. @{$self->{variants}} - 1);
    $self->{correct} = $order[$self->{correct}];
    my @v;
    $v[$order[$_]] = $self->{variants}->[$_] for @order;
    $self->{variants} = \@v;
}

sub post_process {
    $_[0]->check_distinct_variants;
    $_[0]->shuffle_variants;
}

package EGE::GenBase::DirectInput;
use base 'EGE::GenBase';

sub init {
    $_[0]->{type} = 'di';
    $_[0]->{accept} = qr/.+/;
}

sub accept_number {
    $_[0]->{accept} = qr/^\d+$/;
}

sub post_process {
    $_[0]->{correct} =~ $_[0]->{accept} or
        die 'Correct answer is not acceptable in ', ref $_[0], ': ', $_[0]->{correct};
}

package EGE::GenBase::MultipleChoice;
use base 'EGE::GenBase::SingleChoice';

use EGE::Random;

sub init {
    $_[0]->{type} = 'mc';
    $_[0]->{correct} = [];
}

sub shuffle_variants {
    my ($self)= @_;
    $self->{variants} or die;
    my @order = rnd->shuffle(0 .. @{$self->{variants}} - 1);
    my (@v, @c);
    $v[$order[$_]] = $self->{variants}->[$_], $c[$order[$_]] = $self->{correct}->[$_] for @order;
    $self->{variants} = \@v;
    $self->{correct} = \@c;
}

package EGE::GenBase::MultipleChoiceFixedVariants;
use base 'EGE::GenBase::MultipleChoice';

sub shuffle_variants {
}

package EGE::GenBase::Sortable;
use base 'EGE::GenBase::SingleChoice';

use EGE::Random;

sub init {
    $_[0]->{type} = 'sr';
    $_[0]->{correct} = [];
}

sub shuffle_variants {
    my ($self)= @_;
    $self->{variants} or die;
    my @order = rnd->shuffle(0 .. @{$self->{variants}} - 1);
    my (@v, @c);
    for my $o (@order) {
        $v[$order[$o]] = $self->{variants}->[$o];
        my $id = -1;
        for my $i (0..$#{$self->{correct}}) {
            $id = $i if ($self->{correct}->[$i] == $o);
        }
        $c[$id] = $order[$o];
    }
    $self->{variants} = \@v;
    $self->{correct} = \@c;
}

package EGE::GenBase::Match;
use base 'EGE::GenBase::Sortable';

sub init {
    $_[0]->{type} = 'mt';
    $_[0]->{correct} = [];
    $_[0]->{left_column} = [];
}

sub post_process {
    $_[0]->shuffle_variants;
    $_[0]->{variants} = [ $_[0]->{left_column}, $_[0]->{variants} ];
}

package EGE::GenBase::Construct;
use base 'EGE::GenBase';
use EGE::Random;

sub init {
    $_[0]->{type} = 'cn';
    $_[0]->{correct} = [];    
}

sub shuffle_variants {
    my ($self)= @_;
    $self->{variants} or die;
    my @order = rnd->shuffle(0 .. @{$self->{variants}} - 1);
    my (@v, @c);
    for my $o (@order) {
        $v[$order[$o]] = $self->{variants}->[$o];
        my $id = -1;
        for my $i (0..$#{$self->{correct}}) {
            if ($self->{correct}[$i] == $o) {
                $c[$i] = $order[$o]
            }
        }
    }
    $self->{variants} = \@v;
    $self->{correct} = \@c;
}

sub post_process { $_[0]->shuffle_variants; }

1;
