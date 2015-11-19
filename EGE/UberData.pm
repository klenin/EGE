package EGE::UberData;

use strict;
use warnings;


sub digit_to_bin{
my $digit = shift(@_);
my ($i, @res) = (16, ());
    for (0..4){
        if ($digit - $i >= 0){
            push(@res, 1);
            $digit -= $i;           
        }
        else {push(@res, 0);}
        $i /= 2;
    }
@res;
}

sub bin_to_digit{
my ($res, $i) = (0, 1);
foreach (0..4){
    $res += $_[$_] * $i;
    $i *= 2;
}
$res;
}

sub get_question {
 my @arr = ([[1,1,1,1,1],[0,0,0,0,1],[0,0,1,1,0],[1,1,0,0,0]],
[[1,1,1,1,1],[0,0,0,0,1],[0,1,0,1,0],[1,0,1,0,0]],
[[1,1,1,1,1],[0,0,0,0,1],[0,1,1,0,0],[1,0,0,1,0]],
[[1,1,1,1,1],[0,0,0,0,1],[1,0,0,1,0],[0,1,1,0,0]],
[[1,1,1,1,1],[0,0,0,0,1],[1,0,1,0,0],[0,1,0,1,0]],
[[1,1,1,1,1],[0,0,0,0,1],[1,1,0,0,0],[0,0,1,1,0]],
[[1,1,1,1,1],[0,0,0,1,0],[0,0,1,0,1],[1,1,0,0,0]],
[[1,1,1,1,1],[0,0,0,1,0],[0,1,0,0,1],[1,0,1,0,0]],
[[1,1,1,1,1],[0,0,0,1,0],[0,1,1,0,0],[1,0,0,0,1]],
[[1,1,1,1,1],[0,0,0,1,0],[1,0,0,0,1],[0,1,1,0,0]],
[[1,1,1,1,1],[0,0,0,1,0],[1,0,1,0,0],[0,1,0,0,1]],
[[1,1,1,1,1],[0,0,0,1,0],[1,1,0,0,0],[0,0,1,0,1]],
[[1,1,1,1,1],[0,0,0,1,1],[0,0,1,0,0],[1,1,0,0,0]],
[[1,1,1,1,1],[0,0,0,1,1],[0,1,0,0,0],[1,0,1,0,0]],
[[1,1,1,1,1],[0,0,0,1,1],[0,1,1,0,0],[1,0,0,0,0]],
[[1,1,1,1,1],[0,0,0,1,1],[1,0,0,0,0],[0,1,1,0,0]],
[[1,1,1,1,1],[0,0,0,1,1],[1,0,1,0,0],[0,1,0,0,0]],
[[1,1,1,1,1],[0,0,0,1,1],[1,1,0,0,0],[0,0,1,0,0]],
[[1,1,1,1,1],[0,0,1,0,0],[0,0,0,1,1],[1,1,0,0,0]],
[[1,1,1,1,1],[0,0,1,0,0],[0,1,0,0,1],[1,0,0,1,0]],
[[1,1,1,1,1],[0,0,1,0,0],[0,1,0,1,0],[1,0,0,0,1]],
[[1,1,1,1,1],[0,0,1,0,0],[1,0,0,0,1],[0,1,0,1,0]],
[[1,1,1,1,1],[0,0,1,0,0],[1,0,0,1,0],[0,1,0,0,1]],
[[1,1,1,1,1],[0,0,1,0,0],[1,1,0,0,0],[0,0,0,1,1]],
[[1,1,1,1,1],[0,0,1,0,1],[0,0,0,1,0],[1,1,0,0,0]],
[[1,1,1,1,1],[0,0,1,0,1],[0,1,0,0,0],[1,0,0,1,0]],
[[1,1,1,1,1],[0,0,1,0,1],[0,1,0,1,0],[1,0,0,0,0]],
[[1,1,1,1,1],[0,0,1,0,1],[1,0,0,0,0],[0,1,0,1,0]],
[[1,1,1,1,1],[0,0,1,0,1],[1,0,0,1,0],[0,1,0,0,0]],
[[1,1,1,1,1],[0,0,1,0,1],[1,1,0,0,0],[0,0,0,1,0]],
[[1,1,1,1,1],[0,0,1,1,0],[0,0,0,0,1],[1,1,0,0,0]],
[[1,1,1,1,1],[0,0,1,1,0],[0,1,0,0,0],[1,0,0,0,1]],
[[1,1,1,1,1],[0,0,1,1,0],[0,1,0,0,1],[1,0,0,0,0]],
[[1,1,1,1,1],[0,0,1,1,0],[1,0,0,0,0],[0,1,0,0,1]],
[[1,1,1,1,1],[0,0,1,1,0],[1,0,0,0,1],[0,1,0,0,0]],
[[1,1,1,1,1],[0,0,1,1,0],[1,1,0,0,0],[0,0,0,0,1]],
[[1,1,1,1,1],[0,1,0,0,0],[0,0,0,1,1],[1,0,1,0,0]],
[[1,1,1,1,1],[0,1,0,0,0],[0,0,1,0,1],[1,0,0,1,0]],
[[1,1,1,1,1],[0,1,0,0,0],[0,0,1,1,0],[1,0,0,0,1]],
[[1,1,1,1,1],[0,1,0,0,0],[1,0,0,0,1],[0,0,1,1,0]],
[[1,1,1,1,1],[0,1,0,0,0],[1,0,0,1,0],[0,0,1,0,1]],
[[1,1,1,1,1],[0,1,0,0,0],[1,0,1,0,0],[0,0,0,1,1]],
[[1,1,1,1,1],[0,1,0,0,1],[0,0,0,1,0],[1,0,1,0,0]],
[[1,1,1,1,1],[0,1,0,0,1],[0,0,1,0,0],[1,0,0,1,0]],
[[1,1,1,1,1],[0,1,0,0,1],[0,0,1,1,0],[1,0,0,0,0]],
[[1,1,1,1,1],[0,1,0,0,1],[1,0,0,0,0],[0,0,1,1,0]],
[[1,1,1,1,1],[0,1,0,0,1],[1,0,0,1,0],[0,0,1,0,0]],
[[1,1,1,1,1],[0,1,0,0,1],[1,0,1,0,0],[0,0,0,1,0]],
[[1,1,1,1,1],[0,1,0,1,0],[0,0,0,0,1],[1,0,1,0,0]],
[[1,1,1,1,1],[0,1,0,1,0],[0,0,1,0,0],[1,0,0,0,1]],
[[1,1,1,1,1],[0,1,0,1,0],[0,0,1,0,1],[1,0,0,0,0]],
[[1,1,1,1,1],[0,1,0,1,0],[1,0,0,0,0],[0,0,1,0,1]],
[[1,1,1,1,1],[0,1,0,1,0],[1,0,0,0,1],[0,0,1,0,0]],
[[1,1,1,1,1],[0,1,0,1,0],[1,0,1,0,0],[0,0,0,0,1]],
[[1,1,1,1,1],[0,1,1,0,0],[0,0,0,0,1],[1,0,0,1,0]],
[[1,1,1,1,1],[0,1,1,0,0],[0,0,0,1,0],[1,0,0,0,1]],
[[1,1,1,1,1],[0,1,1,0,0],[0,0,0,1,1],[1,0,0,0,0]],
[[1,1,1,1,1],[0,1,1,0,0],[1,0,0,0,0],[0,0,0,1,1]],
[[1,1,1,1,1],[0,1,1,0,0],[1,0,0,0,1],[0,0,0,1,0]],
[[1,1,1,1,1],[0,1,1,0,0],[1,0,0,1,0],[0,0,0,0,1]],
[[1,1,1,1,1],[1,0,0,0,0],[0,0,0,1,1],[0,1,1,0,0]],
[[1,1,1,1,1],[1,0,0,0,0],[0,0,1,0,1],[0,1,0,1,0]],
[[1,1,1,1,1],[1,0,0,0,0],[0,0,1,1,0],[0,1,0,0,1]],
[[1,1,1,1,1],[1,0,0,0,0],[0,1,0,0,1],[0,0,1,1,0]],
[[1,1,1,1,1],[1,0,0,0,0],[0,1,0,1,0],[0,0,1,0,1]],
[[1,1,1,1,1],[1,0,0,0,0],[0,1,1,0,0],[0,0,0,1,1]],
[[1,1,1,1,1],[1,0,0,0,1],[0,0,0,1,0],[0,1,1,0,0]],
[[1,1,1,1,1],[1,0,0,0,1],[0,0,1,0,0],[0,1,0,1,0]],
[[1,1,1,1,1],[1,0,0,0,1],[0,0,1,1,0],[0,1,0,0,0]],
[[1,1,1,1,1],[1,0,0,0,1],[0,1,0,0,0],[0,0,1,1,0]],
[[1,1,1,1,1],[1,0,0,0,1],[0,1,0,1,0],[0,0,1,0,0]],
[[1,1,1,1,1],[1,0,0,0,1],[0,1,1,0,0],[0,0,0,1,0]],
[[1,1,1,1,1],[1,0,0,1,0],[0,0,0,0,1],[0,1,1,0,0]],
[[1,1,1,1,1],[1,0,0,1,0],[0,0,1,0,0],[0,1,0,0,1]],
[[1,1,1,1,1],[1,0,0,1,0],[0,0,1,0,1],[0,1,0,0,0]],
[[1,1,1,1,1],[1,0,0,1,0],[0,1,0,0,0],[0,0,1,0,1]],
[[1,1,1,1,1],[1,0,0,1,0],[0,1,0,0,1],[0,0,1,0,0]],
[[1,1,1,1,1],[1,0,0,1,0],[0,1,1,0,0],[0,0,0,0,1]],
[[1,1,1,1,1],[1,0,1,0,0],[0,0,0,0,1],[0,1,0,1,0]],
[[1,1,1,1,1],[1,0,1,0,0],[0,0,0,1,0],[0,1,0,0,1]],
[[1,1,1,1,1],[1,0,1,0,0],[0,0,0,1,1],[0,1,0,0,0]],
[[1,1,1,1,1],[1,0,1,0,0],[0,1,0,0,0],[0,0,0,1,1]],
[[1,1,1,1,1],[1,0,1,0,0],[0,1,0,0,1],[0,0,0,1,0]],
[[1,1,1,1,1],[1,0,1,0,0],[0,1,0,1,0],[0,0,0,0,1]],
[[1,1,1,1,1],[1,1,0,0,0],[0,0,0,0,1],[0,0,1,1,0]],
[[1,1,1,1,1],[1,1,0,0,0],[0,0,0,1,0],[0,0,1,0,1]],
[[1,1,1,1,1],[1,1,0,0,0],[0,0,0,1,1],[0,0,1,0,0]],
[[1,1,1,1,1],[1,1,0,0,0],[0,0,1,0,0],[0,0,0,1,1]],
[[1,1,1,1,1],[1,1,0,0,0],[0,0,1,0,1],[0,0,0,1,0]],
[[1,1,1,1,1],[1,1,0,0,0],[0,0,1,1,0],[0,0,0,0,1]]);

my @digit  = digit_to_bin(shift(@_));
my $it = int(rand(scalar(@arr)));
my @result = ();
for my $i(0..3){
    for my $j(0..4){
        # print $it, $i, $j, "\n";
        push(@result, 1) if $arr[$it][$i][$j] + $digit[$j] == 0;
        push(@result, 0) if $arr[$it][$i][$j] + $digit[$j] == 1;
        push(@result, 1) if $arr[$it][$i][$j] + $digit[$j] == 2;    
    }
}


my @digitres = ();

for my $i(0..3){
    push(@digitres, bin_to_digit(@result[$i * 5..$i * 5 + 4]))
}

@digitres;
}

1;
