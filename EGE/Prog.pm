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
    my ($self, $fn, $depth) = @_;
    $depth //= 1;
    $fn->($self, $depth);
    $_->visit_dfs($fn, $depth + 1) for $self->_get_children();
    $self;
}
sub _get_children {}

sub count_if {
    my ($self, $cond) = @_;
    my $count = 0;
    $_[0]->visit_dfs( sub { ++$count if $cond->($_[0]) } );
    $count;
}

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

sub _get_children { map $_[0]->{$_}, qw(var expr) }

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

sub _get_children { $_[0]->{array}, @{$_[0]->{indices}} }

package EGE::Prog::BinOp;
use base 'EGE::Prog::SynElement';

sub operand {
    my ($self, $lang, $operand) = @_;
    my $t = $operand->to_lang($lang);
    $operand->isa('EGE::Prog::BinOp') &&
    $lang->{prio}->{$operand->{op}} > $lang->{prio}->{$self->{op}} ?
        "($t)" : $t;
}

sub to_lang {
    my ($self, $lang) = @_;
    sprintf
        $lang->op_fmt($self->{op}),
        map $self->operand($lang, $self->{$_}), qw(left right);
}

sub run {
    my ($self, $env) = @_;
    my $vl = $self->{left}->run($env);
    return $vl if ($env->{_skip} || 0) == ++$env->{_count};
    my $vr = $self->{right}->run($env);
    my $r = eval sprintf EGE::Prog::Lang::lang('Perl')->op_fmt($self->{op}), $vl, $vr;
    my $err = $@;
    $err and die $err;
    $r || 0;
}

sub gather_vars { $_[0]->{$_}->gather_vars($_[1]) for qw(left right) }

sub _get_children { map $_[0]->{$_}, qw(left right) }

package EGE::Prog::UnOp;
use base 'EGE::Prog::SynElement';

sub op_to_lang {
    my ($self, $lang) = @_;
    $lang->translate_un_op->{$self->{op}} || $self->{op};
}

sub to_lang {
    my ($self, $lang) = @_;
    my $arg = $self->{arg}->to_lang($lang);
    $arg = "($arg)" if $self->{arg}->isa('EGE::Prog::BinOp');
    $self->op_to_lang($lang) . " $arg";
}

sub run {
    my ($self, $env) = @_;
    my $v = $self->{arg}->run($env);
    return $v if ($env->{_skip} || 0) == ++$env->{_count};
    my $r = eval $self->op_to_lang(EGE::Prog::Lang::lang('Perl')) . " $v";
    my $err = $@;
    $err and die $err;
    $r || 0;
}

sub gather_vars { $_[0]->{arg}->gather_vars($_[1]) }

sub _get_children { $_[0]->{arg} }

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

sub _get_children { @{$_[0]->{statements}} }

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

sub _get_children { map $_[0]->{$_}, $_->to_lang_fields, 'body' }

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

package EGE::Prog::IfThen;
use base 'EGE::Prog::CompoundStatement';

sub get_formats { qw(if_start_fmt if_end_fmt) }
sub to_lang_fmt { '%2$s' }
sub to_lang_fields { qw(cond) }

sub run {
    my ($self, $env) = @_;
    $self->{body}->run($env) if $self->{cond}->run($env);
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

package EGE::Prog;
use base 'Exporter';

our @EXPORT_OK = qw(make_expr make_block lang_names);

sub make_expr {
    my ($src) = @_;
    ref($src) =~ /^EGE::Prog::/ and return $src;

    if (ref $src eq 'ARRAY') {
        if (@$src >= 2 && $src->[0] eq '[]') {
            my @p = @$src;
            shift @p;
            $_ = make_expr($_) for @p;
            my $array = shift @p;
            return EGE::Prog::Index->new(array => $array, indices => \@p);
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
        die @$src;
    }
    if (ref $src eq 'SCALAR') {
        return EGE::Prog::RefConst->new(ref => $src);
    }
    if (ref $src eq 'CODE') {
        return EGE::Prog::BlackBox->new(code => $src);
    }
    if ($src =~ /^[[:alpha:]][[:alnum:]]*$/) {
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
}}

sub arg_processors {{
    C => sub { $_[0] },
    E => \&make_expr,
    B => \&make_block,
}}

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
}}

1;
