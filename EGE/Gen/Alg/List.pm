# Copyright © 2015 Anton Kim
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Gen::Alg::List;
use base 'EGE::GenBase::Construct';

use strict;
use warnings;
use utf8;

use EGE::Random;

use constant VALUE_COUNT => 3;
use constant COM_COUNT => 4;
use constant VAR_COUNT => 6;

my @command_types = (\&_push, \&_pop, \&_replace, \&_remove);
my @command_names = ('добавить справа %s', 'удалить справа', 'заменить все %s на %s', 'удалить все %s');    
my @arg_count = (1, 0, 2, 1);

sub ls2str { join ',', @_ }
sub str2ls { split ',', $_[0] }
sub cmd2str { sprintf $command_names[shift], @_ }

sub _push {
    my $l = shift;
    push @$l, @_;
}

sub _pop {
    my $l = shift;
    pop @$l;
}

sub _replace { 
    my ($l, $a, $b) = @_;
    s/$a/$b/ for @$l; 
}

sub _remove { 
    my ($l, $a) = @_;
    my @t = @$l;
    pop @$l while scalar(@$l);
    push @$l, grep $_ != $a, @t; 
}

sub exec_cmd {
    my ($l, $cmd_t, @args) = @_;
    $command_types[$cmd_t]->($l, @args);
}

sub rnd_cmd {
    my $cmd_t = rnd->in_range(0, scalar @command_types - 1);
    $cmd_t, $arg_count[$cmd_t] ? rnd->pick_n($arg_count[$cmd_t], 1 .. VALUE_COUNT) : ();
}

sub to_radix {
    my ($a, $radix) = @_;
    my @ret;
    for (0 .. COM_COUNT - 1) { 
        push @ret, $a % $radix; 
        $a = int($a / $radix);
    }
    @ret;
}

sub id2cmds {
    my ($id, @variants) = @_;
    my @radix_id = to_radix $id, scalar @variants;
    map $variants[$_], @radix_id;
}

sub get_cmds_result {
    my ($sl, @cmds) = @_;
    my $ret = [ @$sl ];
    exec_cmd $ret, @$_ for @cmds;
    @$ret;
}

sub get_unique_cmds {
    my ($sl, @variants) = @_;
    my $count = scalar @variants;
    my %result_id;
    
    for (0 .. 50) {
        my $id = rnd->in_range(0, $count ** COM_COUNT - 1);
        my @cmds = id2cmds($id, @variants);
        my $have_compl = 0;
        $have_compl += $_->[0] > 1 for @cmds;
        if ($have_compl) {
            my $res = ls2str(get_cmds_result($sl, @cmds));
            $result_id{$res} = $id;
        }
    }
    for my $id (0 .. $count ** COM_COUNT - 1) {
        my $res = ls2str(get_cmds_result($sl, id2cmds($id, @variants)));
        delete $result_id{$res} if defined $result_id{$res} && $result_id{$res} != $id;
    }

    return 0 unless keys %result_id;
    my $ret = (keys %result_id)[0];
    $ret, to_radix($result_id{$ret}, $count)
}

sub construct_command {
    my ($self) = @_;
    my ($sl, @variants, $el_str, @correct);

    do {
        $sl = [ map rnd->in_range(1, VALUE_COUNT), 0 .. rnd->in_range(1, 3) ];
        my %h;
        $h{ls2str rnd_cmd} = 1  while scalar keys %h < 6;
        @variants = map [ str2ls($_) ], keys %h;
        ($el_str, @correct) = get_unique_cmds($sl, @variants);
    } while (!$el_str);
    my $sl_str = ls2str @$sl;
    $self->{text} = "Выберите набор ровно из " . COM_COUNT . 
        " команд, необходимый для того чтобы из списка <b>($sl_str)</b> получить список <b>($el_str)</b>";
    $self->{variants} = [ map cmd2str(@$_), @variants ];
    $self->{correct} = [ @correct ];
}

1;
