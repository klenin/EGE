# Copyright © 2013 Alexander S. Klenin
# Licensed under GPL version 2 or later.
# http://github.com/klenin/EGE
package EGE::Russian;

use strict;
use warnings;
use utf8;

sub join_comma_and { join(', ', @_[0 .. $#_ - 1]) . ' и ' . $_[-1] }

1;

