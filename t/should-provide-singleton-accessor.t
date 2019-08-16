
use strict;
use warnings;

BEGIN { use FindBin; require "$FindBin::Bin/test-helper.pl" }

use Context::Singleton qw[ singleton ];

plan tests => 2;

my $singleton = singleton 'some singleton';

ok "should return defined value",
	defined $singleton,
	;

is "when called second time should return same value",
	$singleton,
	singleton ('some singleton'),
	;

done_testing;

