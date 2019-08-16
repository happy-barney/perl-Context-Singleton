#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { use FindBin; require "$FindBin::Bin/test-helper.pl" }

plan tests => 2;

deduce_ok "should use default loader class" => (
	rule   => 'Context::Singleton::Class::Load',
	expect => 'Class::Load',
);

deduce_ok "should use default class_loader" => (
	rule   => 'Context::Singleton->load_class',
	expect => \& Class::Load::load_class,
);

done_testing;

