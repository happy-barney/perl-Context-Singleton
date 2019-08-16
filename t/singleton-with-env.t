#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { use FindBin; require "$FindBin::Bin/test-helper.pl" }

plan tests => 2;

singleton "with-existing-env" => (
	env => 'FOO',
	default => "foo-from-default",
);

singleton "with-non-existing-env" => (
	env => 'BAR',
	default => "bar-from-default",
);

$ENV{FOO} = 'foo-from-env';

deduce_ok "should use existing ENV variable" => (
	rule => "with-existing-env",
	value => "foo-from-env",
);

deduce_ok "should fallbeck to default builder if ENV variable doesn't exist" => (
	rule => "with-non-existing-env",
	value => "bar-from-default",
);

done_testing;
