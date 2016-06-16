# Copyright © 2010-2016 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE

use strict;
use warnings;

package EGE::Random::Builtin;

sub new { bless {}, $_[0]; }
sub seed { srand($_[1] + $_[2]) }
sub get { rand($_[1]) }

package EGE::Random::PCG_XSH_RR_64_32;

use Config;

sub new {
    $Config{ivsize} >= 8 or die 'Require 64-bit integers';
    bless { state => 0, inc => 1 }, $_[0];
}

my $mask_32 = 0xffffffff;
my $mask_64 = ($mask_32 << 32) + $mask_32;

sub seed {
    my ($self, $seed, $seq) = @_;
    $self->{state} = 0;
    $self->{inc} = ($seq // 1) * 2 + 1;
    $self->get(1);
    $self->{state} = ($self->{state} + $seed) & $mask_64;
    $self->get(1);
}

# Permuted congruential generator, http://www.pcg-random.org/
sub get {
    my ($self, $max) = @_;
    my $oldstate = $self->{state};
    {
        use integer; # Enforce 64-bit integer multiplication with overflow.
        $self->{state} = ($oldstate * 6364136223846793005 + $self->{inc}) & $mask_64;
    }
    my $xorshifted = ((($oldstate >> 18) ^ $oldstate) >> 27) & $mask_32;
    my $rotate = $oldstate >> 59;
    (($xorshifted >> $rotate) | ($xorshifted << (32 - $rotate)) & $mask_32) % $max;
}

package EGE::Random::PCG_XSH_RR_64_32_BigInt;

use Math::BigInt try => 'GMP';

sub new {
    bless { state => Math::BigInt->bzero, inc => Math::BigInt->bone }, $_[0];
}

sub seed {
    my ($self, $seed, $seq) = @_;
    $self->{state}->bzero;
    $self->{inc} = Math::BigInt->new($seq // 1) * 2 + 1;
    $self->get(1);
    $self->{state}->badd($seed);
    $self->get(1);
}

my $mask_32_ = Math::BigInt->bone->blsft(32)->bdec;
my $mask_64_ = Math::BigInt->bone->blsft(64)->bdec;
my $multiplier = Math::BigInt->new('6364136223846793005');

sub get {
    my ($self, $max) = @_;
    my $oldstate = $self->{state}->copy;
    $self->{state}->bmuladd($multiplier, $self->{inc})->band($mask_64_);
    my $xorshifted = $oldstate->copy->brsft(18)->bxor($oldstate)->brsft(27)->band($mask_32_)->numify;
    my $rotate = $oldstate->brsft(59)->numify;
    (($xorshifted >> $rotate) | (($xorshifted & ((1 << $rotate) - 1)) << (32 - $rotate))) % $max;
}

package EGE::Random;

use utf8;

use Carp;
use Config;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(rnd);

my $rnd;

sub rnd { $rnd ||= __PACKAGE__->new }

sub default_gen { 'PCG_XSH_RR_64_32' . ($Config{ivsize} >= 8 ? '' : '_BigInt') }

sub new {
    my ($class, %p) = @_;
    my $self = { gen => ('EGE::Random::' . ($p{gen} // default_gen))->new };
    bless $self, $class;
    $self->seed($p{seed}, $p{seq});
}

sub seed {
    my ($self, $seed, $seq) = @_;
    $self->{gen}->seed($seed // time, $seq // ($self + 0));
    $self;
}

sub in_range {
    croak 'in_range: bad number of arguments' if @_ != 3;
    my ($self, $lo, $hi) = @_;
    croak 'in_range: hi < lo' if $hi < $lo;
    $self->{gen}->get($hi - $lo + 1) + $lo;
}

sub in_range_except {
    my ($self, $lo, $hi, $except) = @_;
    my @ex = ref $except ? sort { $a <=> $b } @$except : ($except);
    my $r = $self->in_range($lo, $hi - @ex);
    for (@ex) {
        last if $_ > $r;
        $r++;
    }
    $r;
}

sub pick {
    my ($self, @array) = @_;
    @array or croak 'pick from empty array';
    @array[$self->{gen}->get(scalar @array)];
}

# Не проверяя, предполагает, что $except явлется элементом @array.
sub pick_except {
    my ($self, $except, @array) = @_;
    @array > 1 or die 'except nothing';
    my $i = $self->{gen}->get($#array);
    $array[$i] eq $except ? $array[-1] : $array[$i];
}

sub pick_n {
    my ($self, $n, @array) = @_;
    croak "pick_n: $n of " . scalar @array if $n > @array;
    --$n;
    for (0 .. $n) {
        my $pos = $self->in_range($_, $#array);
        @array[$_, $pos] = @array[$pos, $_];
    }
    @array[0 .. $n];
}

# Выражение вида sort rnd->pick_n вызывает синтаксическую ошибку,
# поэтому заводим специальную функцию.
sub pick_n_sorted {
    my $self = shift;
    sort $self->pick_n(@_);
}

sub coin { $_[0]->{gen}->get(2) }

sub shuffle {
    my $self = shift;
    $self->pick_n(scalar @_, @_);
}

sub index_var {
    my ($self, $n) = @_;
    $self->pick_n($n || 1, 'i', 'j', 'k', 'a', 'b', 'c')
}

sub english_letter { $_[0]->pick('a' .. 'z') }

sub russian_letter {
    my ($self) = @_;
    chr([ord('а') .. ord('я')]->[rnd->in_range(0, 31)]);
}

sub russian_consonant_letter {
    my ($self) = @_;
    $self->get_letter_from_string('бвгджзклмнпрстфх');
}

sub russian_vowel_letter {
    my ($self) = @_;
    $self->get_letter_from_string('аеиоуыэюя');
}

sub pretty_russian_letter {
    my ($self) = @_;
    $self->get_letter_from_string('абвгдежзиклмнопрстуфхэя');
}

sub get_letter_from_string {
    my ($self, $string) = @_;
    substr($string, rnd->in_range(0, length($string) - 1), 1);
}

sub split_number {
    my ($self, $number, $parts) = @_;
    die if $parts > $number;
    my @p = sort { $a <=> $b } $self->pick_n($parts - 1, 1 .. $number - 1);
    $p[0], map($p[$_] - $p[$_ - 1], 1 .. $#p), $number - $p[-1];
}

sub const_value {
    $_[0]->pick(10, 100, 1000, 10000, 42);
}

1;
