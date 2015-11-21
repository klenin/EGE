use Test::Harness;

runtests(map "$_.t", qw(
    bits complexity database html logic notation num_text processor prog random russian utils));

1;
