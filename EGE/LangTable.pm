package EGE::LangTable;

use strict;
use warnings;

use EGE::Prog;

sub row {
    my $r = join '', map "<td>$_</td>", @_;
    "<tr>$r</tr>\n";
}

sub lang_row {
    my $prog = shift;
    row(map EGE::Prog::lang_names->{$_}, @_) .
    row(map '<pre>' . $prog->to_lang_named($_) . '</pre>', @_);
}

sub table {
    my ($prog, $rows) = @_;
    my $r = join '', map lang_row($prog, @$_), @$rows;
    qq~<table border="1">\n$r</table>\n~;
}

1;
