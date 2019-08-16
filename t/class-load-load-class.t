#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { use FindBin; require "$FindBin::Bin/test-helper.pl" }

plan tests => 2;

arrange {
	contrive 'Class::Foo->accessor' => (
		class => 'Class::Foo',
		as => sub { $_[0]->can ('load_class') },
	);

	proclaim 'Class::Foo' => deduce ('Context::Singleton->load_class')
		->('Examples::Class::Loader')
		;
};

deduce_ok "should provide loaded class name" => (
	rule   => 'Class::Foo',
	expect => 'Examples::Class::Loader',
);

deduce_ok "should provide loaded class accessor" => (
	rule   => 'Class::Foo->accessor',
	expect => \& Examples::Class::Loader::load_class,
);

done_testing;

