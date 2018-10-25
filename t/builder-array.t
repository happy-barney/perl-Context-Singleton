
use strict;
use warnings;

use Test::More tests => 1 + 1;
use Test::Warnings;

use Context::Singleton;

contrive 'instance' => (
	as => sub { 1 },
);

is
	deduce ('instance'),
	1,
	"Should not need empty arrayref to deduce plain subroutine",
	;

