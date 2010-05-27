use Test::Harness;

runtests(map "$_.t", qw(bits logic prog random));

1;
