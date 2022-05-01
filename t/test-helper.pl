
use v5.10;
use strict;
use warnings;

use Test::More import => [qw[
	!cmp_ok
	!is
	!is_deeply
	!ok
]];
use Test::Deep qw[
	!cmp_bag
	!cmp_deeply
	!cmp_methods
	!cmp_set
];
use Test::Warnings qw[
	:no_end_test
	had_no_warnings
];

use Safe::Isa;
use Ref::Util;

use Context::Singleton;

sub it {
	my ($title, %params) = @_;

	my $got    = $params{got};
	my $expect = $params{expect};

	if (Ref::Util::is_coderef ($got)) {
		my $result;
		my $lives = eval { $result = $got->(); 1 };
		my $error = $@;

		unless ($lives) {
			return Test::Deep::cmp_deeply $error, $params{throws}, $title
				if exists $params{throws};

			fail $title;
			diag "Expected to live by died with:", explain $error;
			return;
		}

		if (exists $params{throws}) {
			fail $title;
			diag "Expected to die but lived";
			return;
		}

		$got = $result;
	}

	return Test::More::ok (($got xor $expect->{val}), $title)
		if $expect->$_isa (Test::Deep::Boolean::);

	Test::Deep::cmp_deeply $got, $expect, $title;
}

sub ok {
	my ($title, %params) = @_;

	it $title, %params, expect => bool (1);
}

1;

