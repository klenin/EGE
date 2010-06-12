use Test::Harness;

runtests(map "$_.t", qw(bits logic notation num_text prog random));

1;
