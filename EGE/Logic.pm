# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Logic;

use strict;
use warnings;
use utf8;

use EGE::Prog qw(make_expr);
use EGE::Random;
use EGE::Bits;

sub maybe_not { rnd->pick($_[0], $_[0], [ '!', $_[0] ]) }

sub random_op {
    my @common = ('&&', '||');
    my @rare = ('=>', '^');
    my @all = (@common, @common, @common, @rare);
    rnd->pick(@all);
}

sub random_logic {
    my ($v1, $v2) = @_;
    return rnd->coin if !@_;
    return maybe_not($_[0]) if @_ == 1;

    my $p = rnd->in_range(1, @_ - 1);
    maybe_not [
        random_op,
        random_logic(@_[0 .. $p - 1]),
        random_logic(@_[$p .. $#_])
    ];
}

sub random_logic_expr { make_expr(random_logic @_) }

sub bits_to_vars {
    my ($bits, @names) = @_;
    my $i = 0;
    return { map { $_ => $bits->get_bit($i++) } @names };
}

sub truth_table_string {
    my ($expr) = @_;
    $expr->gather_vars(\my %vars);
    %vars or return $expr->run({});
    my @names = sort keys %vars;
    my $bits = EGE::Bits->new->set_size(scalar @names);
    my $r = '';
    do {
        $r .= $expr->run(bits_to_vars($bits, @names));
        $bits->inc;
    } until $bits->is_empty;
    $r;
}

sub is_unop { $_[0]->isa('EGE::Prog::UnOp') }
sub is_binop { $_[0]->isa('EGE::Prog::BinOp') }

sub equiv_not1 {
    my ($e) = @_;
    my ($op, $el, $er) = @$e{qw(op left right)};
    my $nel = [ '!', $el ];
    my $ner = [ '!', $er ];
    make_expr(
        $op eq '&&' ? [ '||', $nel, $ner ] :
        $op eq '||' ? [ '&&', $nel, $ner ] :
        $op eq '^'  ? [ '^' , $nel, $er  ] :
        $op eq '=>' ? [ '&&', $el , $ner ] : die $op
    );
}

sub equiv_not {
    my ($e) = @_;
    is_unop($e) && is_binop($e->{arg}) ? equiv_not1($e->{arg}) :
    is_binop($e) ? make_expr([ '!', equiv_not1($e) ]) :
    make_expr([ '!', [ '!', $e ] ]);
}

1;
