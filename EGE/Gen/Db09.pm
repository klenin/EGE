# Copyright © 2014 Darya D. Gornak
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE

package EGE::Gen::Db09;
use base 'EGE::GenBase::SingleChoice';

use strict;
use warnings;
use utf8;

use EGE::Random;
use EGE::Prog;
use EGE::Prog::Lang;
use EGE::Html;
use EGE::SQL::Table;
use EGE::SQL::Queries;
use EGE::SQL::Utils;

sub create_table {
    my $table_PC = EGE::SQL::Table->new([ qw(id name_PC) ], name => 'PC');
    my $table_Printer = EGE::SQL::Table->new([ qw(id name_Printer) ], name => 'Printer');
    my $table_Laptop = EGE::SQL::Table->new([ qw(id name_Laptop) ], name => 'Laptop');
    my $table_relations = EGE::SQL::Table->new([ qw(id_buyer id_pc id_printer id_laptop) ], name => 'relations');
    my @PC = rnd->pick_n_sorted(6, @EGE::Russian::Product::PC);
    my @Printer = rnd->pick_n_sorted(6, @EGE::Russian::Product::Printer);
    my @Laptop = rnd->pick_n_sorted(6, @EGE::Russian::Product::Laptop);
    my @id_Pc = rnd->pick_n(6, 1 .. @PC+1);
    my @id_printer = rnd->pick_n(6, @PC+1 .. @PC+@Printer+1);
    my @id_Laptop = rnd->pick_n(6, @PC+@Printer+1..@PC+@Printer+@Laptop+1);
    $table_PC->insert_rows(@{EGE::Utils::transpose(\@id_Pc, \@PC)});
    $table_Printer->insert_rows(@{EGE::Utils::transpose(\@id_printer, \@Printer)});
    $table_Laptop->insert_rows(@{EGE::Utils::transpose(\@id_Laptop, \@Laptop)});
    my @id_buyer = rnd->pick_n(8, 1 .. 12);
    for (@id_buyer) {
        $table_relations->insert_row($_, rnd->pick(@id_Pc), rnd->pick(@id_printer), rnd->pick(@id_Laptop));
    }
    $table_PC, $table_Printer, $table_Laptop, $table_relations, \@id_buyer;
}

sub inner_join {
    my ($self) = @_;
    my ($table_PC, $table_Printer, $table_Laptop, $table_relations, $id_b) = create_table();
    my (@requests, $query);
    my @id = @$id_b;
    my ($f1) = rnd->shuffle(@id[1 .. $#id]);
    my $inner1 = EGE::SQL::Inner_join->new(
        { tab => $table_relations, field => 'id_pc' },
        { tab => $table_PC, field => 'id' });
    my $inner2 = EGE::SQL::Inner_join->new(
        { tab => $inner1, field => 'id_printer' },
        { tab => $table_Printer, field => 'id' });
    my $inner3 = EGE::SQL::Inner_join->new(
        { tab => $inner2, field => 'id_laptop' },
        { tab => $table_Laptop, field => 'id' });
    my $where = EGE::Prog::make_expr([ '==', 'id_buyer', $f1 ]);
    $query = EGE::SQL::Select->new($inner3, ['name_PC', 'name_Printer', 'name_Laptop'], $where);
    push @requests, EGE::SQL::Select->new($inner2, ['name_PC', 'name_Printer', 'name_Laptop'], $where)->text_html;
    push @requests, EGE::SQL::Select->new($inner3, ['name_PC'], $where)->text_html;
    push @requests, EGE::SQL::Select->new($inner3, ['name_PC', 'name_Printer', 'name_Laptop'],
        EGE::Prog::make_expr([ '!=', 'id_buyer', $f1 ]))->text_html;
    $self->{text} = sprintf
        "В фрагменте базы данных интернет-магазина представлены сведения о покупках:\n%s\n" .
        'Какой из приведенных ниже запросов покажет названия продуктов приобретенных покупателем с id = %s?',
        EGE::SQL::Utils::multi_table_html($table_PC, $table_Printer, $table_Laptop, $table_relations), $f1;
    $self->variants($query->text_html, @requests);
}

1;
