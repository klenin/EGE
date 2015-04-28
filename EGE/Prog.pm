# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
use strict;
use warnings;
use utf8;

use EGE::Utils;
use EGE::Prog::Lang;
package EGE::Prog::SynElement;

sub new {
    my ($class, %init) = @_;
    my $self = { %init };
    bless $self, $class;
    $self;
}

sub to_lang_named {
    my ($self, $lang_name, $unformated) = @_;
    $self->to_lang(EGE::Prog::Lang::lang($lang_name), $unformated);
}

sub to_lang { die; }
sub run { die; }
sub get_ref { die; }

sub run_val {
    my ($self, $name, $env) = @_;
    $env ||= {};
    $self->run($env);
    $env->{$name};
}

sub gather_vars {}

sub visit_dfs {
    my (undef, $fn, $depth) = @_;
    $depth //= 1;
    $fn->($_[0], $depth);
    $_[0]->_visit_children($fn, $depth + 1);
    $_[0];
}

sub _visit_children {}

sub count_if {
    my ($self, $cond) = @_;
    my $count = 0;
    $_[0]->visit_dfs( sub { ++$count if $cond->($_[0]) } );
    $count;
}

sub get_type { (split ':', ref $_[0])[-1] }

sub complexity { die; }

sub needs_parens { 0 }

package EGE::Prog::BlackBox;
use base 'EGE::Prog::SynElement';

sub to_lang_named {
    my ($self, $lang_name) = @_;
    $self->{lang}->{$lang_name} // die;
}

sub to_lang { $_[0]->to_lang_named($_[1]->name); }

sub run {
    my ($self, $env) = @_;
    $self->{code}->($env);
}

package EGE::Prog::Assign;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    sprintf $lang->assign_fmt,
        map $self->{$_}->to_lang($lang), qw(var expr);
}

sub run {
    my ($self, $env) = @_;
    ${$self->{var}->get_ref($env)} = $self->{expr}->run($env);
}

sub _visit_children { my $self = shift; $self->{$_}->visit_dfs(@_) for qw(var expr) }

sub complexity {
    my ($self, $env, $mistakes, $iter, $rnd_case) = @_;
    my $name;
    defined($name = $self->{var}->{name}) or return ();
    defined $iter->{$name} and die "Assign to iterator: '$name'";

    # провека, что все переменные expr определены
    $self->{expr}->polinom_degree($env, $mistakes, $iter, $rnd_case);
    # вычисляем степень выражения без итераторов, если ошибка, значит в выражении присутсвует итератор
    $env->{$self->{var}->{name}} = eval { $self->{expr}->polinom_degree($env, $mistakes, {}, $rnd_case) };
    $@ and die "Assign iterator to: '$name'";
    ()
}

package EGE::Prog::Index;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    sprintf $lang->index_fmt,
        $self->{array}->to_lang($lang),
        join ', ', map $_->to_lang($lang), @{$self->{indices}};
}

sub run {
    my ($self, $env) = @_;
    my $v = $self->{array}->run($env);
    $v = $v->[$_->run($env)] for @{$self->{indices}};
    $v;
}

sub get_ref {
    my ($self, $env) = @_;
    my $v = $self->{array}->get_ref($env);
    $v = \($$v->[$_->run($env)]) for @{$self->{indices}};
    $v;
}

sub _visit_children { my $self = shift; $_->visit_dfs(@_) for $self->{array}, @{$self->{indices}} }

package EGE::Prog::CallFunc;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    sprintf $lang->call_func_fmt,
        $self->{func},
        join $lang->args_separator, map $_->to_lang($lang), @{$self->{args}};
}

sub run {
    my ($self, $env) = @_;
    my @arg_val = map $_->run($env), @{$self->{args}};
    my $func = $env->{'&'}->{$self->{func}} or die "Undefined function $self->{func}";
    $func->call( [ @arg_val ], $env);
}

package EGE::Prog::Print;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    sprintf $lang->print_fmt,
        join $lang->args_separator, map $_->to_lang($lang), @{$self->{args}};
}

sub run {
    my ($self, $env) = @_;
    $env->{'<out>'} .= ($env->{'<out>'} ? "\n" : '') . join(' ', map $_->run($env), @{$self->{args}});
}

package EGE::Prog::Op;
use base 'EGE::Prog::SynElement';

sub _children {}

sub run {
    my ($self, $env) = @_;
    my $r = eval sprintf $self->run_fmt(), map $self->{$_}->run($env), $self->_children;
    my $err = $@;
    $err and die $err;
    $r || 0;
}

sub prio { $_[1]->{prio}->{$_[0]->{op}} or die $_[0]->{op} }

sub operand {
    my ($self, $lang, $operand) = @_;
    my $t = $operand->to_lang($lang);
    $operand->needs_parens($lang, $self->prio($lang)) ? "($t)" : $t;
}

sub to_lang {
    my ($self, $lang) = @_;
    sprintf
        $self->to_lang_fmt($lang, $self->{op}),
        map $self->operand($lang, $self->{$_}), $self->_children;
}

sub needs_parens {
    my ($self, $lang, $parent_prio) = @_;
    $parent_prio < $self->prio($lang);
}

sub run_fmt { $_[0]->to_lang_fmt(EGE::Prog::Lang::lang('Perl')) }
sub to_lang_fmt {}

sub gather_vars { $_[0]->{$_}->gather_vars($_[1]) for $_[0]->_children; }
sub _visit_children { my $self = shift; $self->{$_}->visit_dfs(@_) for $self->_children; }

sub polinom_degree { die "Polinom degree is unavaible for expr with operator: '$_[0]->{op}'"; }

package EGE::Prog::BinOp;
use base 'EGE::Prog::Op';
use List::Util;

sub to_lang_fmt {
    my ($self, $lang) = @_;
    $lang->op_fmt($self->{op});
}

sub _children { qw(left right) }

sub polinom_degree {
    my $self = shift;
    my ($env, $mistakes, $iter) = @_;
    $self->{op} eq '*' ? List::Util::sum(map $self->{$_}->polinom_degree(@_), $self->_children) :
    $self->{op} eq '+' ? List::Util::max(map $self->{$_}->polinom_degree(@_), $self->_children) :
    $self->{op} eq '**' ? $self->{left}->polinom_degree(@_) * $self->{right}->run({}) :
    $self->SUPER::polinom_degree(@_)
}

package EGE::Prog::UnOp;
use base 'EGE::Prog::Op';

sub prio { $_[1]->{prio}->{'`' . $_[0]->{op}} or die $_[0]->{op} }

sub to_lang_fmt {
    my ($self, $lang) = @_;
    ($lang->translate_un_op->{$self->{op}} || $self->{op}) . ' %s';
}

sub _children { qw(arg) }

package EGE::Prog::Inc;
use base 'EGE::Prog::UnOp';

sub to_lang_fmt {
    my ($self, $lang) = @_;
    $lang->translate_un_op->{$self->{op}} || $self->{op};
}

sub run {
    my ($self, $env) = @_;
    eval sprintf $self->{op}, '${$self->{arg}->get_ref($env)}';
}

package EGE::Prog::TernaryOp;
use base 'EGE::Prog::Op';

sub to_lang_fmt {
    my ($self, $lang) = @_;
    my $r = $lang->op_fmt($self->{op});
    return $r unless ref $r;
    my $s = EGE::Prog::make_expr($r)->to_lang($lang);
    $s =~ s/(\d+)/%$1\$s/g;
    $s;
}

sub _children { qw(arg1 arg2 arg3) }

package EGE::Prog::Var;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    sprintf $lang->var_fmt, $self->{name};
}

sub run {
    my ($self, $env) = @_;
    for ($env->{$self->{name}}) {
        defined $_ or die "Undefined variable $self->{name}";
        return $_;
    }
}

sub get_ref {
    my ($self, $env, $value) = @_;
    \$env->{$self->{name}};
}

sub gather_vars { $_[1]->{$_[0]->{name}} = 1 }

sub polinom_degree {
    my ($self, $env, $mistakes, $iter) = @_;
    my $name = $self->{name};
    defined $env->{$name} and return $mistakes->{var_as_const} ? $name eq $mistakes->{var_as_const} : $env->{$name};
    defined $iter->{$name} and return $mistakes->{var_as_const} ? 0 : $iter->{EGE::Utils::last_key($iter, $name)};
    die "Undefined variable $name";
}

package EGE::Prog::Const;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    $self->{value};
}

sub run {
    my ($self, $env) = @_;
    $self->{value} + 0;
}

sub polinom_degree { 0 }

package EGE::Prog::RefConst;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    ${$self->{ref}};
}

sub run {
    my ($self, $env) = @_;
    ${$self->{ref}} + 0;
}

package EGE::Prog::Block;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang, $unformated) = @_;
    join $lang->block_stmt_separator, map $_->to_lang($lang, $unformated), @{$self->{statements}};
};

sub run {
    my ($self, $env) = @_;
    $_->run($env) for @{$self->{statements}};
}

sub _visit_children { my $self = shift; $_->visit_dfs(@_) for @{$self->{statements}} }

sub complexity {
    my $self = shift;
    $_[1]->{change_min} and return List::Util::min(map($_->complexity(@_), @{$self->{statements}})) || 0;
    List::Util::max(map($_->complexity(@_), @{$self->{statements}})) || 0;
}

package EGE::Prog::CompoundStatement;
use base 'EGE::Prog::SynElement';

sub to_lang_fields {}

sub to_lang {
    my ($self, $lang, $unformated) = @_;
    my $body_is_block = @{$self->{body}->{statements}} > 1;
    no strict 'refs';
    my ($fmt_start, $fmt_end) =
        map $lang->$_($body_is_block || $unformated), $self->get_formats;
    my $body = $self->{body}->to_lang($lang, $unformated);
    
    $body =~ s/^/  /mg if $fmt_start =~ /\n$/; # отступы
    sprintf
        $fmt_start . $self->to_lang_fmt . $fmt_end,
        map($self->{$_}->to_lang($lang, $unformated), $self->to_lang_fields), $body;
}

sub _visit_children { my $self = shift; $self->{$_}->visit_dfs(@_) for $_->to_lang_fields, 'body' }

package EGE::Prog::ForLoop;
use base 'EGE::Prog::CompoundStatement';

sub get_formats { qw(for_start_fmt for_end_fmt) }
sub to_lang_fmt { '%4$s' }
sub to_lang_fields { qw(var lb ub) }

sub run {
    my ($self, $env) = @_;
    my $i = $self->{var}->get_ref($env);
    for ($$i = $self->{lb}->run($env); $$i <= $self->{ub}->run($env); ++$$i) {
        $self->{body}->run($env);
    }
}

sub complexity {
    my ($self, $env, $mistakes, $iter, $rnd_case) = @_;
    my $name = $self->{var}->{name};
    my $degree = $self->{ub}->polinom_degree($env, $mistakes, $iter, $rnd_case);
    $iter->{$name} = $degree;

    my $body_complexity = $self->{body}->complexity($env, $mistakes, $iter, $rnd_case);
    $env->{$name} = $degree;
    my $cur_complexity = List::Util::sum(grep $_ =~ m/^[\d|.]+$/, values %$iter) || 0;
    delete $iter->{$name};
    $cur_complexity > $body_complexity ? $cur_complexity : $body_complexity;
}

package EGE::Prog::IfThen;
use base 'EGE::Prog::CompoundStatement';

sub get_formats { qw(if_start_fmt if_end_fmt) }
sub to_lang_fmt { '%2$s' }
sub to_lang_fields { qw(cond) }

sub run {
    my ($self, $env) = @_;
    $self->{body}->run($env) if $self->{cond}->run($env);
}

sub complexity {
    my $self = shift;
    my ($env, $mistakes, $iter, $rnd_case) = @_;
    my ($cond, $body) = ($self->{cond}, $self->{body});
    my @sides = qw(left right);

    if ($cond->{op} eq '==') {
        my $is_vars = 1;
        $is_vars &&= $cond->{$_}->get_type eq 'Var' for @sides;
        if ($is_vars)
        {
            my @names = map $cond->{$_}->{name}, @sides;
            ($mistakes->{ignore_if_eq} || $names[0] eq $names[1]) and return $body->complexity(@_);
            defined $iter->{$names[0]} and defined $iter->{$names[1]} or
                die "IfThen complexity with condition a == b, expected both var as iterator";

            my ($old_val, $new_val, $side);
            $_ = EGE::Utils::last_key($iter, $_) for @names;
            $side = $iter->{$names[1]} > $iter->{$names[0]};
            $new_val = $names[!$side];
          
            ($old_val, $iter->{$names[$side]}) = ($iter->{$names[$side]}, $new_val);
            my $ret = $body->complexity(@_);
            $iter->{$names[$side]} = $old_val;
            return $ret;
        }

        my $isno_const;
        ($cond->{$sides[$_]}->get_type eq 'Const') and ($isno_const = $cond->{$sides[!$_]})  for 0 .. 1;
        if (defined $isno_const && defined $isno_const->{op} && $isno_const->{op} eq '%') {
            $mistakes->{ignore_if_mod} and return $body->complexity(@_);
            my $name = $isno_const->{left}->{name};
            defined $iter->{$name} or die "IfThen complexity with condition a % b == 0, expected a as iterator, given: '$isno_const->{left}'";
            $name = EGE::Utils::last_key($iter, $name);
            my $n = $isno_const->{right}->polinom_degree(@_);

            my $old_val = $iter->{$name};
            $iter->{$name} -= $n;
            $iter->{$name} < 0 and $iter->{$name} = 0;
            my $ret = $body->complexity(@_);
            $iter->{$name} = $old_val;
            return $ret;
        }
        if (defined $isno_const && $isno_const->get_type eq 'Var') {
            $mistakes->{ignore_if_mod} and return $body->complexity(@_);
            my $name = EGE::Utils::last_key($iter, $isno_const->{name});
            my $old_val = $iter->{$name};
            $iter->{$name} = 0;
            my $ret = $body->complexity(@_);
            $iter->{$name} = $old_val;
            return $ret;
        }
    }
    elsif (my $side = $cond->{op} eq '>=' or $cond->{op} eq '<=') {
        my @operands = qw(left right);
        my $name = $cond->{$operands[$side]}->{name} or
            die "IfThen complexity with condition a >= b, expected b as var, got $cond->{$operands[$side]}";
        defined $iter->{$name} or die "IfThen complexity with condition a >= b, expected b as iterator, $name is not iterator";
        $name = EGE::Utils::last_key($iter, $name);
        my $old_val = $iter->{$name};
        my $new_val = $cond->{$operands[!$side]}->polinom_degree(@_);
        ($mistakes->{ignore_if_less} || $new_val >= $old_val) and return $body->complexity(@_);

        $iter->{$name} = $new_val;
        my $ret = $body->complexity(@_);
        $iter->{$name} = $old_val;
        return $ret;
    }
    else {
        die "IfThen complexity for condition with operator: '$cond->{op}' is unavaible";
    }

}

package EGE::Prog::CondLoop;
use base 'EGE::Prog::CompoundStatement';

package EGE::Prog::While;
use base 'EGE::Prog::CondLoop';

sub get_formats { qw(while_start_fmt while_end_fmt) }
sub to_lang_fmt { '%2$s' }
sub to_lang_fields { qw(cond) }

sub run {
    my ($self, $env) = @_;
    $self->{body}->run($env) while $self->{cond}->run($env);
}

package EGE::Prog::Until;
use base 'EGE::Prog::CondLoop';

sub get_formats { qw(until_start_fmt until_end_fmt) }
sub to_lang_fmt { '%2$s' }
sub to_lang_fields { qw(cond) }

sub run {
    my ($self, $env) = @_;
    $self->{body}->run($env) until $self->{cond}->run($env);
}

package EGE::Prog::PlainText;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    my $t = $self->{text};
    ref $t eq 'HASH' ? $t->{$lang->name} || '' : $t;
};

sub run {
    defined wantarray and die "required value of plain text: '$_[0]->{text}'";
}

package EGE::Prog::ExprStmt;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    sprintf $lang->expr_fmt, $self->{expr}->to_lang($lang);
}

sub run {
    my ($self, $env) = @_;
    $self->{expr}->run($env);
};

sub complexity { 0 }

package EGE::Prog::FuncDef;
use base 'EGE::Prog::CompoundStatement';

sub get_formats { qw(func_start_fmt func_end_fmt) }
sub to_lang_fmt { '%3$s' }
sub to_lang_fields { qw(name params) }

sub run {
    my ($self, $env) = @_;
    $env->{'&'}->{$self->{name}->{name}} and die "Redefinition of function $self->{name}->{name}";
    $env->{'&'}->{$self->{name}->{name}} = $self;
}

sub call {
    my ($self, $args, $env) = @_;
    my $act_len = @$args;
    my $form_len = @{$self->{params}->{names}};
    $act_len > $form_len and die "Too many arguments to function $self->{name}->{name}";
    $act_len < $form_len and die "Too few arguments to function $self->{name}->{name}";
    
    my $new_env = { '&' => $env->{'&'}, map(($_ => shift @$args), @{$self->{params}->{names}}) };
    $self->{body}->run_val($self->{name}->{name}, $new_env);
}

package EGE::Prog::FuncParams;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    join $lang->args_separator, map sprintf($lang->args_fmt, $_), @{$self->{names}};
}

sub run {
}

package EGE::Prog::FuncName;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    $self->{name};
}

sub run {
}

package EGE::Prog;
use base 'Exporter';

our @EXPORT_OK = qw(make_expr make_block lang_names);

sub make_expr {
    my ($src) = @_;
    ref($src) =~ /^EGE::Prog::/ and return $src;
    if (ref $src eq 'ARRAY') {
        if (@$src == 2 && $src->[0] eq '#') {
            return EGE::Prog::PlainText->new(text => $src->[1]);
        }
        if (@$src >= 2 && $src->[0] eq '[]') {
            my @p = @$src;
            shift @p;
            $_ = make_expr($_) for @p;
            my $array = shift @p;
            return EGE::Prog::Index->new(array => $array, indices => \@p);
        }
        if (@$src >= 2 && $src->[0] eq '()') {
            my @p = @$src;
            shift @p;
            my $func = shift @p;
            $_ = make_expr($_) for @p;
            return EGE::Prog::CallFunc->new(func => $func, args => \@p);
        }
        if (@$src >= 1 && $src->[0] eq 'print') {
            my @p = @$src;
            shift @p;
            $_ = make_expr($_) for @p;
            return EGE::Prog::Print->new(args => \@p);
        }
        if (@$src == 2 && $src->[0] =~ /\+\+|--/) {
            return EGE::Prog::Inc->new(
                op => $src->[0], arg => make_expr($src->[1]));
        }
        if (@$src == 2) {
            return EGE::Prog::UnOp->new(
                op => $src->[0], arg => make_expr($src->[1]));
        }
        if (@$src == 3) {
            return EGE::Prog::BinOp->new(
                op => $src->[0],
                left => make_expr($src->[1]),
                right => make_expr($src->[2])
            );
        }
        if (@$src == 4) {
            return EGE::Prog::TernaryOp->new(
                op => $src->[0],
                map { +"arg$_" => make_expr($src->[$_]) } 1..3
            );
        }
        die @$src;
    }
    if (ref $src eq 'SCALAR') {
        return EGE::Prog::RefConst->new(ref => $src);
    }
    if (ref $src eq 'CODE') {
        return EGE::Prog::BlackBox->new(code => $src);
    }
    if ($src =~ /^[[:alpha:]][[:alnum:]_]*$/) {
        return EGE::Prog::Var->new(name => $src);
    }
    return EGE::Prog::Const->new(value => $src);
}

sub statements_descr {{
    '#' => { type => 'PlainText', args => ['C_text'] },
    '=' => { type => 'Assign', args => [qw(E_var E_expr)] },
    'for' => { type => 'ForLoop', args => [qw(E_var E_lb E_ub B_body)] },
    'if' => { type => 'IfThen', args => [qw(E_cond B_body)] },
    'while' => { type => 'While', args => [qw(E_cond B_body)] },
    'until' => { type => 'Until', args => [qw(E_cond B_body)] },
    'func' => { type => 'FuncDef', args => [qw(N_name P_params B_body)] },
    'expr' => { type => 'ExprStmt', args => [qw(E_expr)] },
}}

sub arg_processors {{
    C => sub { $_[0] },
    E => \&make_expr,
    B => \&make_block,
    P => \&make_func_params,
    N => \&make_func_name,
}}

sub make_func_name {
    my ($src) = @_;
    EGE::Prog::FuncName->new(name => $src);
}

sub make_func_params {
    my ($src) = @_;
    ref $src eq 'ARRAY' or die;
    EGE::Prog::FuncParams->new(names => $src);
}

sub make_statement {
    my ($next) = @_;
    my $name = $next->();
    my $d = statements_descr->{$name};
    $d or die "Unknown statement $name";
    my %args;
    for (@{$d->{args}}) {
        my ($p, $n) = /(\w)_(\w+)/;
        $args{$n} = arg_processors->{$p}->($next->());
    }
    "EGE::Prog::$d->{type}"->new(%args);
}

sub make_block {
    my ($src) = @_;
    ref $src eq 'ARRAY' or die;
    my @s;
    for (my $i = 0; $i < @$src; ) {
        push @s, make_statement(sub { $src->[$i++] });
    }
    EGE::Prog::Block->new(statements => \@s);
}

sub lang_names() {{
  'Basic' => 'Бейсик',
  'Pascal' => 'Паскаль',
  'C' => 'Си',
  'Alg' => 'Алгоритмический',
  'SQL' => 'Структурированный язык запросов',
  'Perl' => 'Перл',
}}

1;
