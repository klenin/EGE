package EGE::Logic;

use strict;
use warnings;
use utf8;

use Bit::Vector;

use EGE::Prog qw(make_expr);
use EGE::Random;

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
