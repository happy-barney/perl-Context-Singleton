#!/usr/bin/perl env

use strict;
use warnings;

BEGIN { use FindBin; require "$FindBin::Bin/test-helper.pl" }

plan tests => 2;

arrange {
	contrive 'autoloaded-class' => (
		class => 'Sample::Class::Autoload',
		builder => 'builder_method',
	);
};

deduce_ok 'should autoload class' => (
	rule   => 'Sample::Class::Autoload',
	expect => 'Sample::Class::Autoload',
);

deduce_ok 'identify autoloaded class' => (
	rule   => 'autoloaded-class',
	expect => 'Sample::Class::Autoload::builder_method called',
);

done_testing;
