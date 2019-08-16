#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { use FindBin; require "$FindBin::Bin/test-helper.pl" }

require Examples::Class::Loader;

plan tests => 2;

arrange {
	proclaim 'Context::Singleton::Class::Load' => 'Examples::Class::Loader';
};

deduce_ok "should use custom loader class" => (
	rule   => 'Context::Singleton::Class::Load',
	expect => 'Examples::Class::Loader',
);

deduce_ok "should use custom overloaded class_loader" => (
	rule   => 'Context::Singleton->load_class',
	expect => \& Examples::Class::Loader::load_class,
);

done_testing;

