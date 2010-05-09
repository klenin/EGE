package EGE::LangTable;

use strict;
use warnings;

use EGE::Prog;
use EGE::Html;

sub lang_row {
    my $prog = shift;
    html->row_n('th', map EGE::Prog::lang_names->{$_}, @_) .
    html->row_n('td',
        map '<pre><![CDATA[' . $prog->to_lang_named($_) . ']]></pre>', @_);
}

sub unpre { "]]></pre>$_[0]<pre><![CDATA[" }

sub table {
    my ($prog, $rows) = @_;
    my $r = join '', map lang_row($prog, @$_), @$rows;
    html->table("\n$r", { border => 1 }) . "\n";
}

1;
