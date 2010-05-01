use strict;
use warnings;

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

sub count_ops { 0 }

sub run_val {
    my ($self, $name, $env) = @_;
    $env ||= {};
    $self->run($env);
    $env->{$name};
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

sub count_ops { $_[0]->{expr}->count_ops; }

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

sub count_ops {
    my ($self) = @_;
    my $count = 0;
    $count += $_->count_ops for @{$self->{indices}};
}

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
    my $op = $self->{op};
    $op = ($env->{_replace_op} || {})->{$op} || $op;
    eval sprintf EGE::Prog::Lang::lang('Perl')->op_fmt($op), $vl, $vr;
}

sub count_ops { $_[0]->{left}->count_ops + $_[0]->{right}->count_ops + 1; }

package EGE::Prog::UnOp;
use base 'EGE::Prog::SynElement';

sub op_to_lang { $_[0] }

sub to_lang {
    my ($self, $lang) = @_;
    $self->{op} . $self->{arg}->to_lang($lang);
}

sub run {
    my ($self, $env) = @_;
    my $v = $self->{arg}->run($env);
    return $v if ($env->{_skip} || 0) == ++$env->{_count};
    eval "$self->{op} $v";
}

sub count_ops { $_[0]->{arg}->count_ops + 1; }

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
    join "\n", map $_->to_lang($lang), @{$self->{statements}};
};

sub run {
    my ($self, $env) = @_;
    $_->run($env) for @{$self->{statements}};
}

sub count_ops {
    my $count = 0;
    $count += $_->count_ops for @{$_[0]->{statements}};
    $count;
}

package EGE::Prog::ForLoop;
use base 'EGE::Prog::SynElement';

sub to_lang {
    my ($self, $lang) = @_;
    my $fmt_start = $lang->for_start_fmt;
    my $fmt_end = $lang->for_end_fmt;
    my $body = $self->{body}->to_lang($lang);
    $body =~ s/^/  /mg; # отступы
    sprintf
        "$fmt_start\n%4\$s\n$fmt_end",
        map($self->{$_}->to_lang($lang), qw(var lb ub)), $body;
};

sub run {
    my ($self, $env) = @_;
    my $i = $self->{var}->get_ref($env);
    for ($$i = $self->{lb}->run($env); $$i <= $self->{ub}->run($env); ++$$i) {
        $self->{body}->run($env);
    }
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
    if (ref $src =~ /^EGE::Prog::/) {
        return $src;
    }
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
    if ($src =~ /^[A-Za-z][A-Za-z0-9]*$/) {
        return EGE::Prog::Var->new(name => $src);
    }
    return EGE::Prog::Const->new(value => $src);
}

sub statements_descr {{
    '#' => { type => 'LangSpecificText', args => ['C_text'] },
    '=' => { type => 'Assign', args => [qw(E_var E_expr)] },
    'for' => { type => 'ForLoop', args => [qw(E_var E_lb E_ub B_body)] },
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
}}

1;
