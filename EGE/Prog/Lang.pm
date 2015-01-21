# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
use strict;
use warnings;
use utf8;

package ops;

sub mult { '*', '/', '%', '//' }
sub add { '+', '-' }
sub comp { '>', '<', '==', '!=', '>=', '<=' }
sub logic { '&&', '||', '^', '=>' }
sub unary { '!', '+', '-' }
sub prio_unary { map "`$_", unary }

sub between { between => [ '&&', [ '<=', 2, 1 ], [ '<=', 1, 3 ] ] }

package EGE::Prog::Lang;

my %lang_cache;

sub lang {
    my ($name) = @_;
    $lang_cache{$name} ||= "EGE::Prog::Lang::$name"->new;
}

sub new {
    my ($class, %init) = @_;
    my $self = { %init };
    bless $self, $class;
    $self->make_priorities;
    $self;
}

sub op_fmt {
    my ($self, $op) = @_;
    my $fmt = $self->translate_op->{$op} || $op;
    $fmt = '%%' if $fmt eq '%';
    ref $fmt || $fmt =~ /%\w/ ? $fmt : "%s $fmt %s";
}

sub name {
    ref($_[0]) =~ /::(\w+)$/;
    $1;
}

sub var_fmt { '%s' }

sub make_priorities {
    my ($self) = @_;
    my @raw = $self->prio_list;
    for my $prio (1 .. @raw) {
        $self->{prio}->{$_} = $prio for @{$raw[$prio - 1]};
    }
}

sub prio_list {
    [ ops::prio_unary ], [ ops::mult ], [ ops::add ],
    [ ops::comp ], [ '^', '=>' ], [ '&&' ], [ '||' ], [ 'between' ],
}

sub translate_un_op { {} }

sub block_stmt_separator { "\n" }
sub args_separator { ", "}
sub args_fmt { "%s" }
sub call_func_fmt { "%s(%s)" }

package EGE::Prog::Lang::Basic;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s = %s' }
sub index_fmt { '%s(%s)' }
sub translate_op {{
    '%' => 'MOD', '//' => '\\',
    '==' => '=', '!=' => '<>',
    '&&' => 'AND', '||' => 'OR', '^' => 'XOR', '=>' => 'IMP',
    ops::between,
}}
sub translate_un_op { { '!' => 'NOT' } }

sub for_start_fmt { "FOR %s = %s TO %s\n" }
sub for_end_fmt { "\nNEXT %1\$s" }

sub if_start_fmt { 'IF %s THEN' . ($_[1] ? "\n" : ' ') }
sub if_end_fmt { $_[1] ? "\nEND IF" : '' }

sub while_start_fmt { "DO WHILE %s\n" }
sub while_end_fmt { "\nEND DO" }

sub until_start_fmt { "DO UNTIL %s\n" }
sub until_end_fmt { "\nEND DO" }

sub func_start_fmt { "FUNCTION %s(%s)\n" }
sub func_end_fmt { "\nEND FUNCTION" }

sub print_fmt { "PRINT %s" }

package EGE::Prog::Lang::C;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s = %s;' }
sub index_fmt { '%s[%s]' }
sub translate_op { { '//' => 'int(%s / %s)', '=>' => '<=', ops::between } }

sub for_start_fmt {
    'for (%s = %2$s; %1$s <= %3$s; ++%1$s)' . ($_[1] ? '{' : '') . "\n"
}
sub for_end_fmt { $_[1] ? "\n}" : '' }

sub if_start_fmt { 'if (%s)' . ($_[1] ? " {\n" : "\n") }
sub if_end_fmt { $_[1] ? "\n}" : '' }

sub while_start_fmt { 'while (%s)' . ($_[1] ? " {\n" : "\n") }
sub while_end_fmt { $_[1] ? "\n}" : '' }

sub until_start_fmt { 'while (!(%s))' . ($_[1] ? " {\n" : "\n") }
sub until_end_fmt { $_[1] ? "\n}" : '' }

sub func_start_fmt { "int %s(%s) {\n  int %1\$s;\n" }
sub func_end_fmt { "\n  return %1\$s;\n}" }

sub print_fmt { 
    "print(%s)"
}

sub args_fmt {"int %s"}
package EGE::Prog::Lang::Pascal;
use base 'EGE::Prog::Lang';

sub prio_list {
    [ ops::prio_unary ], [ ops::mult, '&&' ],
    [ ops::add, '||', '^' ], [ ops::comp, '=>' ], [ 'between' ]
}

sub assign_fmt { '%s := %s;' }
sub index_fmt { '%s[%s]' }
sub translate_op {{
    '%' => 'mod', '//' => 'div',
    '==' => '=', '!=' => '<>',
    '&&' => 'and', '||' => 'or', '^' => 'xor', '=>' => '<=',
    between => 'InRange(%s, %s, %s)',
}}
sub translate_un_op { { '!' => 'not' } }

sub for_start_fmt { 'for %s := %s to %s do' . ($_[1] ? ' begin' : '') . "\n" }
sub for_end_fmt { $_[1] ? "\nend;" : '' }

sub if_start_fmt { 'if %s then' . ($_[1] ? " begin\n" : "\n") }
sub if_end_fmt { $_[1] ? "\nend;" : '' }

sub while_start_fmt { 'while %s do' . ($_[1] ? " begin\n" : "\n") }
sub while_end_fmt { $_[1] ? "\nend;" : '' }

sub until_start_fmt { 'while not (%s) do' . ($_[1] ? " begin\n" : "\n") }
sub until_end_fmt { $_[1] ? "\nend;" : '' }

sub func_start_fmt { "Function %s(%s: integer):integer; begin\n" }
sub func_end_fmt { "\nend;" }

sub print_fmt { "write(%s)" }

package EGE::Prog::Lang::Alg;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s := %s' }
sub index_fmt { '%s[%s]' }
sub translate_op {{
    '==' => '=', '!=' => '≠',
    '%' => 'mod(%s, %s)', '//' => 'div(%s, %s)',
    '&&' => 'и', '||' => 'или', '=>' => '→',
    ops::between,
}}
sub translate_un_op { { '!' => 'не' } }

sub for_start_fmt { "нц для %s от %s до %s\n" }
sub for_end_fmt { "\nкц" }

sub if_start_fmt { "если %s то\n" }
sub if_end_fmt { "\nвсе" }

sub while_start_fmt { "пока %s нц\n" }
sub while_end_fmt { "\nкц" }

sub until_start_fmt { "пока не (%s) нц\n" }
sub until_end_fmt { "\nкц" }

sub func_start_fmt { "алг цел %s(цел %s) нач\n" }
sub func_end_fmt { "\nкон;" }

sub print_fmt { "вывод %s" }

package EGE::Prog::Lang::Perl;
use base 'EGE::Prog::Lang';

sub var_fmt { '$%s' }
sub assign_fmt { '%s = %s;' }
sub index_fmt { '$%s[%s]' }
sub translate_op { { '//' => 'int(%s / %s)', '=>' => '<=', ops::between } }

sub for_start_fmt { 'for (%s = %2$s; %1$s <= %3$s; ++%1$s) {' . "\n" }
sub for_end_fmt { "\n}" }

sub if_start_fmt { "if (%s) {\n" }
sub if_end_fmt { "\n}" }

sub while_start_fmt { "while (%s) {\n" }
sub while_end_fmt { "\n}" }

sub until_start_fmt { "until (%s) {\n" }
sub until_end_fmt { "\n}" }

sub func_start_fmt { "sub %s {\n  (%s) = \@_;\n" }
sub func_end_fmt { "\n  \$%1\$s;\n}" }

sub print_fmt { 'print(%s, "\n")' }

sub args_fmt { "\$%s" }
package EGE::Prog::Lang::Logic;
use base 'EGE::Prog::Lang';

sub prio_list {
    [ ops::prio_unary ], [ ops::mult ], [ ops::add ],
    [ ops::comp ], [ '&&' ], [ '||', '^' ], [ '=>' ]
}

sub translate_op {{
    '-' => '−', '*' => '⋅',
    '!=' => '≠', '>=' => '≥', '<=' => '≤',
    '&&' => '∧', '||' => '∨', '^' => '⊕', '=>' => '→'
}}

sub translate_un_op { { '!' => '¬' } }

package EGE::Prog::Lang::SQL;
use base 'EGE::Prog::Lang';

sub translate_op {{
     '==' => '=', '!=' => '<>','&&' => 'AND', '||' => 'OR',
     between => '%s BETWEEN %s AND %s',
}}

sub translate_un_op {{ '!' => 'NOT' }}

sub assign_fmt { '%s = %s' }
sub block_stmt_separator { ', ' }

1;
