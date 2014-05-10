use Test::Harness;

runtests(map "$_.t", qw(bits database logic notation num_text processor prog random utils));

1;
