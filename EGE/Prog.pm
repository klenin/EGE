# Copyright © 2010 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
use strict;
use warnings;
use utf8;

use EGE::Prog::Lang;
package EGE::Prog::SynElement;

sub new {
    my ($class, %init) = @_;
    my $self = { %init };
    bless $self, $class;
    $self;
}

sub to_lang_named {
    my ($self, $lang_name) = @_;
    $self->to_lang(EGE::Prog::Lang::lang($lang_name));
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

sub complexity { 0 }

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
    my ($self, $env, $mistakes, $iter) = @_;
    if (defined $self->{var}->{name}) {
        $env->{$self->{var}->{name}} = $self->{expr}->polinom_degree($env, $mistakes, $iter);
    }
    ();
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
    my $args = [map $_->run($env), @{$self->{args}}];
    my $func = $env->{'&'}->{$self->{func}};
    defined $func or die "Undefined function $self->{func}";    
    $func->call($args, $env);
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
    push($env->{"<out>"}, join(' ', map $_->run($env), @{$self->{args}}));
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

sub polinom_degree { 0 }

package EGE::Prog::BinOp;
use base 'EGE::Prog::Op';

sub to_lang_fmt {
    my ($self, $lang) = @_;
    $lang->op_fmt($self->{op});
}

sub _children { qw(left right) }

sub polinom_degree {
    my ($self, $env, $mistakes, $iter) = @_;

    if ($self->{op} eq '*') { $self->{left}->polinom_degree($env, $mistakes, $iter) + $self->{right}->polinom_degree($env, $mistakes, $iter) } 
    elsif ($self->{op} eq '+' || $self->{op} eq '-') { List::Util::max(map($self->{$_}->polinom_degree($env, $mistakes, $iter), $self->_children)) } 
    else { die "polinom degree is unavaible for Expr with operator: '$self->{op}'" }
}

package EGE::Prog::UnOp;
use base 'EGE::Prog::Op';

sub prio { $_[1]->{prio}->{'`' . $_[0]->{op}} or die $_[0]->{op} }

sub to_lang_fmt {
    my ($self, $lang) = @_;
    ($lang->translate_un_op->{$self->{op}} || $self->{op}) . ' %s';
}

sub _children { qw(arg) }

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
    for ($env->{$self->{name}}) {                   # Зачем здесь цикл?!
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
    my $name = $_[0]->{name};
    defined $env->{$name} and   return $mistakes->{var_as_const}? $name eq $mistakes->{var_as_const} : $env->{$name};
    defined $iter->{$name} and  return $mistakes->{var_as_const}? 0 : $iter->{$name};
    die "Undefined variable $self->{name}";
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
    my ($self, $lang) = @_;
    join $lang->block_stmt_separator, map $_->to_lang($lang), @{$self->{statements}};
};

sub run {
    my ($self, $env) = @_;
    $_->run($env) for @{$self->{statements}};
}

sub _visit_children { my $self = shift; $_->visit_dfs(@_) for @{$self->{statements}} }

sub complexity { 
    my ($self, $env, $mistakes, $iter, $repeat) = @_;
    $env ||= {};
    $iter ||= {};
    $repeat ||= 0;
    if ($mistakes->{change_min}) { 
        return List::Util::min(map($_->complexity($env, $mistakes, $iter, $repeat), @{$self->{statements}})) || 0; 
    }    
    List::Util::max(map($_->complexity($env, $mistakes, $iter, $repeat), @{$self->{statements}})) or 0; 
}

package EGE::Prog::CompoundStatement;
use base 'EGE::Prog::SynElement';

sub to_lang_fields {}

sub to_lang {
    my ($self, $lang) = @_;
    my $body_is_block = @{$self->{body}->{statements}} > 1;
    no strict 'refs';
    my ($fmt_start, $fmt_end) =
        map $lang->$_($body_is_block), $self->get_formats;
    my $body = $self->{body}->to_lang($lang);
    $body =~ s/^/  /mg if $fmt_start =~ /\n$/; # отступы
    sprintf
        $fmt_start . $self->to_lang_fmt . $fmt_end,
        map($self->{$_}->to_lang($lang), $self->to_lang_fields), $body;
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
    my ($self, $env, $mistakes, $iter, $repeat) = @_;
    my $name = $self->{var}->{name};
    my $degree = $self->{ub}->polinom_degree($env, $mistakes, $iter);
    $iter->{$name} = $degree;
    $repeat += $degree;

    my $body_complexity = $self->{body}->complexity($env, $mistakes, $iter, $repeat);
    
    $env->{$name} = $degree;
    delete $iter->{$name};
    $repeat > $body_complexity? $repeat: $body_complexity;
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
    my ($self, $env, $mistakes, $iter, $repeat) = @_;
    my ($cond, $body) = ($self->{cond}, $self->{body});
    my @operands = qw(left right);

    if ($mistakes->{ignore_if}) { return $body->complexity($env, $mistakes, $iter, $repeat); }
    if ($cond->{op} eq '==' and 
        defined $iter->{$cond->{right}->{name}} and
        defined $iter->{$cond->{left}->{name}}) {
        my $side = $iter->{$cond->{right}->{name}} > $iter->{$cond->{left}->{name}};

        my $old_val;
        $repeat -= $old_val = $iter->{$cond->{$operands[$side]}->{name}};
        $iter->{$cond->{$operands[$side]}->{name}} = $iter->{$cond->{$operands[!$side]}->{name}};
        my $ret = $body->complexity($env, $mistakes, $iter, $repeat);
        $iter->{$cond->{$operands[$side]}->{name}} = $old_val;
        $repeat += $iter->{$cond->{$operands[$side]}->{name}};
        return $ret;
    }
    else {die "ifThen complexity for $cond->{op} condition is unavaible"}
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

package EGE::Prog::LangSpecificText;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    $self->{text}->{$lang->name} || '';
};

sub run {}

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


package EGE::Prog::FuncDef;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    my ($fmt_start, $fmt_end) = ($lang->func_start_fmt(), $lang->func_end_fmt());
    my $body = $self->{body}->to_lang($lang);
    $body =~ s/^/  /mg if $fmt_start =~ /\n$/; # отступы
    sprintf
        $fmt_start . $body . $fmt_end,
        $self->{name}, $self->{args}->to_lang($lang);
}

sub run {
    my ($self, $env) = @_;
    $env->{'&'} ||= {};
    $env->{'&'}->{$self->{name}} = $self;
}

sub call {
    my ($self, $args, $env) = @_;
    $env->{'<out>'} ||= [];
    my $new_env = {
        '&' => $env->{'&'},
        '<out>' => $env->{'<out>'},
    };
    my @act_args = @$args;
    my @form_args = @{$self->{args}->{names}};
    @act_args > @form_args and die "too many arguments to function $self->{name}";    
    @act_args < @form_args and die "too few arguments to function $self->{name}";   
    for (0 .. @act_args-1){
        my $name = $self->{args}->{names}->[$_];
        $new_env->{ $name } = $args->[$_];    
    }
    $self->{body}->run_val($self->{name}, $new_env);
}

package EGE::Prog::FuncArgs;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    join $lang->args_separator, map sprintf($lang->args_fmt, $_), @{$self->{names}};    
}

sub run {
}

package EGE::Prog;
use base 'Exporter';

our @EXPORT_OK = qw(make_expr make_block lang_names);

sub make_expr {
    my ($src) = @_;
    ref($src) =~ /^EGE::Prog::/ and return $src;
	if (!defined($src)){
		1;
	}
		
    if (ref $src eq 'ARRAY') {
        if (@$src >= 2 && $src->[0] eq '[]') {
            my @p = @$src;
            shift @p;
            $_ = make_expr($_) for @p;
            my $array = shift @p;
            return EGE::Prog::Index->new(array => $array, indices => \@p);
        }
        if (@$src == 3 && $src->[0] eq '()') {
            my @p = @$src;
            shift @p; 
            my $func = shift @p;
            my $args = $p[0];
            $args = [map make_expr($_), @$args];
            return EGE::Prog::CallFunc->new(func => $func, args => $args);
        }   
        if (@$src == 2 && $src->[0] eq 'print') {
            my @p = @$src;
            shift @p;
            my $args = $p[0];
            $args = [map make_expr($_), @$args];
            return EGE::Prog::Print->new(args => $args);
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
    '#' => { type => 'LangSpecificText', args => ['C_text'] },
    '=' => { type => 'Assign', args => [qw(E_var E_expr)] },
    'for' => { type => 'ForLoop', args => [qw(E_var E_lb E_ub B_body)] },
    'if' => { type => 'IfThen', args => [qw(E_cond B_body)] },
    'while' => { type => 'While', args => [qw(E_cond B_body)] },
    'until' => { type => 'Until', args => [qw(E_cond B_body)] },
    'func' => { type => 'FuncDef', args => [qw(C_name A_args B_body)]},
    'expr' => { type => 'ExprStmt', args => [qw(E_expr)]},
}}

sub arg_processors {{
    C => sub { $_[0] },
    E => \&make_expr,
    B => \&make_block,
    A => \&make_func_args,
}}

sub make_func_args
{
    my ($src) = @_;
    ref $src eq 'ARRAY' or die;
    EGE::Prog::FuncArgs->new(names => $src);
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
