#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { use FindBin; require "$FindBin::Bin/test-helper.pl" }

plan tests => 1;

singleton "with-default" => (
	default => "foo",
);

deduce_ok "should deduce singleton's default value" => (
	rule => "with-default",
	value => "foo",
);

done_testing;
