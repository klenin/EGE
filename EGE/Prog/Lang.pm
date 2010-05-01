use strict;
use warnings;

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
    $self;
}

sub op_fmt {
    my ($self, $op) = @_;
    my $fmt = $self->translate_op->{$op} || $op;
    $fmt = '%%' if $fmt eq '%';
    $fmt =~ /%\w/ ? $fmt : "%s $fmt %s";
}

sub name {
    ref($_[0]) =~ /::(\w+)$/;
    $1;
}

sub var_fmt { '%s' }

package EGE::Prog::Lang::Basic;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s = %s' }
sub index_fmt { '%s(%s)' }
sub translate_op { { '%' => 'MOD', '//' => '\\' } }
sub for_start_fmt { 'FOR %s = %s TO %s' }
sub for_end_fmt { 'NEXT %1$s' }

package EGE::Prog::Lang::C;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s = %s;' }
sub index_fmt { '%s[%s]' }
sub translate_op { { '//' => 'int(%s / %s)', } }
sub for_start_fmt { 'for(%s = %2$s; %1$s <= %3$s; ++%1$s) {' }
sub for_end_fmt { '}' }

package EGE::Prog::Lang::Pascal;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s := %s;' }
sub index_fmt { '%s[%s]' }
sub translate_op { { '%' => 'mod', '//' => 'div', } }
sub for_start_fmt { 'for %s := %s to %s do begin' }
sub for_end_fmt { 'end;' }

package EGE::Prog::Lang::Alg;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s := %s' }
sub index_fmt { '%s[%s]' }
sub translate_op { { '%' => 'mod(%s, %s)', '//' => 'div(%s, %s)', } }
sub for_start_fmt { 'нц для %s от %s до %s' }
sub for_end_fmt { 'кц' }

package EGE::Prog::Lang::Perl;
use base 'EGE::Prog::Lang';

sub assign_fmt { '%s = %s;' }
sub index_fmt { '$%s[%s]' }
sub translate_op { { '//' => 'int(%s / %s)', } }
sub for_start_fmt { 'for(%s = %2$s; %1$s <= %3$s; ++%1$s) {' }
sub for_end_fmt { '}' }
sub var_fmt { '$%s' }

1;
