# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
use strict;
use warnings;
use utf8;


package ops;

sub power { '**' }
sub mult { '*', '/', '%', '//' }
sub add { '+', '-' }
sub comp { '>', '<', '==', '!=', '>=', '<=' }
sub logic { '&&', '||', '^', '=>', 'eq' }
sub bitwise { '&', '|' }
sub unary { '++%s', '--%s', '%s++', '%s--', '!', '+', '-' }
sub prio_unary { map "`$_", unary }

sub between { between => [ '&&', [ '<=', 2, 1 ], [ '<=', 1, 3 ] ] }

package EGE::Prog::Lang;
use EGE::Html;

sub new {
    my ($class, %init) = @_;
    my $self = { %init };
    bless $self, $class;
    $self->make_priorities;
    $self;
}

sub to_html {
    my %subs = (
        '<' => '&lt;',
        '>' => '&gt;',
        '&' => '&amp;',
    );
    my $keys = join '|', keys %subs;
    $_[0] =~ s/($keys)/$subs{$1}/g;
}

sub op_fmt {
    my ($self, $op) = @_;
    my $fmt = $self->translate_op->{$op} || $op;
    $fmt = '%%' if $fmt eq '%';
    ref $fmt || $fmt =~ /%\w/ ? $fmt : "%s $fmt %s";
}

sub un_op_fmt {
    my ($self, $op) = @_;
    my $fmt = $self->translate_un_op->{$op} || $op;
    $fmt =~ m/%s/ ? $fmt : $fmt . ' %s';
}

sub name {
    ref($_[0]) =~ /::(\w+)$/;
    $1;
}

sub print_tag {
    my ($self, $t) = @_;
    $t->{$_} ||= '' for qw(left inner right tag alt);
    $self->{html} ?
        $t->{left} . html->tag($t->{tag}, $t->{inner}) . $t->{right} :
        $t->{left} . $t->{alt} . $t->{inner} . $t->{right};
}

sub get_fmt {
    my ($self, $name_fmt, @args) = @_;
    my $fmt = $self->$name_fmt(@args);
    return $self->print_tag($fmt) if ref $fmt eq 'HASH';
    to_html($fmt) if $self->{html};
    $fmt;
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
    [ ops::prio_unary ], [ ops::power ], [ ops::mult ], [ ops::add ],
    [ ops::comp ], [ '^', '=>', ops::bitwise ], [ '&&' ], [ '||' ], [ 'between' ],
}

sub translate_un_op { {} }

sub block_stmt_separator { "\n" }

sub args_separator { ', '}
sub args_fmt { '%s' }

sub call_func_fmt { '%s(%s)' }

sub expr_fmt { '%s' }

sub p_func_start_fmt { $_[0]->c_func_start_fmt; }
sub p_func_end_fmt { $_[0]->c_func_end_fmt; }

sub p_return_fmt { $_[0]->c_return_fmt; }

package EGE::Prog::Lang::Basic;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s = %s' }
sub index_fmt { '%s(%s)' }
sub translate_op {{
    '**' => '^',
    '%' => 'MOD', '//' => '\\',
    '==' => '=', '!=' => '<>',
    '&&' => 'AND', '||' => 'OR', '^' => 'XOR', '=>' => 'IMP', 'eq' => 'EQV',
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

sub c_func_start_fmt { "FUNCTION %s(%s)\n" }
sub c_func_end_fmt { "\nEND FUNCTION\n" }

sub print_fmt { 'PRINT %s' }

sub c_return_fmt { 'Return %s' }

package EGE::Prog::Lang::C;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s = %s;' }
sub index_fmt { '%s[%s]' }
sub translate_op {{
    '**' => 'pow(%s, %s)', '//' => 'int(%s / %s)', '=>' => '<=', 'eq' => '==', ops::between
}}

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

sub c_func_start_fmt { "int %s(%s) {\n" }
sub c_func_end_fmt { "\n}\n" }

sub p_func_start_fmt { "int %s(%s) {\n  int %1\$s;\n" }
sub p_func_end_fmt { "\n  return %1\$s;\n}\n" }

sub print_fmt { 'print(%s)' }

sub expr_fmt { '%s;' }

sub args_fmt {'int %s'}

sub c_return_fmt { 'return %s;' }

package EGE::Prog::Lang::Pascal;
use base 'EGE::Prog::Lang';

sub prio_list {
    [ ops::prio_unary ], [ ops::power ], [ ops::mult, '&&' ],
    [ ops::add, '||', '^' ], [ ops::comp, '=>', 'eq' ], [ 'between' ]
}

sub assign_fmt { '%s := %s;' }
sub index_fmt { '%s[%s]' }
sub translate_op {{
    '%' => 'mod', '//' => 'div',
    '==' => '=', '!=' => '<>',
    '&&' => 'and', '||' => 'or', '^' => 'xor', '=>' => '<=', 'eq' => '=',
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

sub c_func_start_fmt { "function %s(%s: integer): integer;\nbegin\n" }
sub c_func_end_fmt { "\nend;\n" }

sub print_fmt { 'write(%s)' }

sub expr_fmt { '%s;' }

sub c_return_fmt { 'exit(%s);' }
sub p_return_fmt { 'exit;' }

package EGE::Prog::Lang::Alg;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s := %s' }
sub index_fmt { '%s[%s]' }
sub translate_op {{
    '==' => '=', '!=' => '≠',
    '%' => 'mod(%s, %s)', '//' => 'div(%s, %s)',
    '&&' => 'и', '||' => 'или', '=>' => '→', 'eq' => '≡',
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

sub c_func_start_fmt { "алг цел %s(цел %s)\nнач\n" }
sub c_func_end_fmt { "\nкон\n" }

sub print_fmt { 'вывод %s' }

sub c_return_fmt { 'выход_алг %s | выход_алг выраж - оператор выхода из алгоритма, с возвращением результата выраж' }
sub p_return_fmt { 'выход_алг | выход_алг - оператор выхода из алгоритма' }

package EGE::Prog::Lang::Perl;
use base 'EGE::Prog::Lang';

sub var_fmt { '$%s' }
sub assign_fmt { '%s = %s;' }
sub index_fmt { '$%s[%s]' }
sub translate_op { { '//' => 'int(%s / %s)', '=>' => '<=', 'eq' => '==', ops::between } }

sub for_start_fmt { 'for (%s = %2$s; %1$s <= %3$s; ++%1$s) {' . "\n" }
sub for_end_fmt { "\n}" }

sub if_start_fmt { "if (%s) {\n" }
sub if_end_fmt { "\n}" }

sub while_start_fmt { "while (%s) {\n" }
sub while_end_fmt { "\n}" }

sub until_start_fmt { "until (%s) {\n" }
sub until_end_fmt { "\n}" }

sub c_func_start_fmt { "sub %s {\n  my (%s) = \@_;\n" }
sub c_func_end_fmt { "\n}\n" }

sub p_func_start_fmt { "sub %s {\n  my \$%1\$s;\n  my (%s) = \@_;\n" }
sub p_func_end_fmt { "\n  return \$%1\$s;\n}\n" }

sub print_fmt { 'print(%s)' }

sub expr_fmt { '%s;' }

sub args_fmt { '$%s' }

sub c_return_fmt { 'return %s;' }

package EGE::Prog::Lang::Logic;
use base 'EGE::Prog::Lang';

sub prio_list {
    [ ops::prio_unary ], [ ops::power ], [ ops::mult ], [ ops::add ],
    [ ops::comp ], [ '&&' ], [ '||', '^' ], [ '=>', 'eq' ]
}

sub index_fmt { { left => '%s', inner => '%s', tag => 'sub', alt => '_' } }

sub translate_op {{
    '**' => { left => '%s', inner => '%s', tag => 'sup', alt => ' ^ ' },
    '-' => '−', '*' => '⋅',
    '==' => '=', '!=' => '≠', '>=' => '≥', '<=' => '≤',
    '&&' => '∧', '||' => '∨', '^' => '⊕', '=>' => '→', 'eq' => '≡',
}}

sub var_fmt { { inner => '%s', tag => 'i' } }

sub call_func_fmt { { inner => '%s', tag => 'i', right => '(%s)' } }

sub translate_un_op { { '!' => '¬' } }

package EGE::Prog::Lang::SQL;
use base 'EGE::Prog::Lang';

sub translate_op {{
    '**' => 'POWER(%s, %s)',
    '==' => '=', '!=' => '<>','&&' => 'AND', '||' => 'OR',
    between => '%s BETWEEN %s AND %s',
}}

sub translate_un_op {{ '!' => 'NOT' }}

sub assign_fmt { '%s = %s' }
sub block_stmt_separator { ', ' }

1;
