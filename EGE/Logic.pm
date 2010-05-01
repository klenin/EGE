package EGE::Logic;

use strict;
use warnings;
use utf8;

use Bit::Vector;

use EGE::Prog qw(make_expr);
use EGE::Random;

sub maybe_not { rnd->pick($_[0], $_[0], [ '!', $_[0] ]) }

sub random_logic_2 {
    my ($v1, $v2) = @_;
    [ rnd->pick(ops::logic), maybe_not($v1), maybe_not($v2) ];
}

sub random_logic_expr_2 { make_expr(random_logic_2 @_) }

sub random_logic_expr_3 {
    my ($v1, $v2, $v3) = @_;

    make_expr(rnd->coin ?
        random_logic_2(random_logic_2($v1, $v2), $v3) :
        random_logic_2($v1, random_logic_2($v2, $v3))
    );
}

sub truth_table_string {
    my ($expr, @vars) = @_;
    @vars or return $expr->run({});
    my $bits = Bit::Vector->new(scalar @vars);
    my $r = '';
    my %h;
    for my $i (1 .. 2 ** @vars) {
        $h{$vars[$_]} = ($bits->bit_test($_) || 0) for 0 .. $#vars;
        $r .= $expr->run(\%h);
        $bits->increment;
    }
    $r;
}

1;
