# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

use strict;
use warnings;

package EGE::GenBase;

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

sub shuffle_variants {
    my ($self)= @_;
    $self->{variants} or die;
    my @order = rnd->shuffle(0 .. @{$self->{variants}} - 1);
    $self->{correct} = $order[$self->{correct}];
    my @v;
    $v[$order[$_]] = $self->{variants}->[$_] for @order;
    $self->{variants} = \@v;
}

sub post_process { $_[0]->shuffle_variants; }

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

1;
