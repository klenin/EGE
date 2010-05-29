use Test::Harness;

runtests(map "$_.t", qw(bits logic num_text prog random));

1;
