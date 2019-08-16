
use strict;
use warnings;

use Test::Builder;
use Test::Deep;
use Test::More qw[];
use Test::Warnings qw[ :no_end_test had_no_warnings ];

use FindBin;
use lib "$FindBin::Bin/lib";

use Context::Singleton;

my $Test = Test::Builder->new;

sub deduce_ok {
	my ($title, %params) = @_;

	my $value;
	my $lives = eval { $value = deduce $params{rule}; 1 };
	my $error = $@;

	unless ($lives) {
		$Test->ok (0, $title);
		$Test->diag ("died with exception $error");
		return;
	}

	return $Test->ok (1, $title)
		unless exists $params{expect};

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	return cmp_deeply $value, $params{expect}, $title;
}

sub ok {
	push @_, shift @_;

	goto \& Test::More::ok;
}

sub is {
	push @_, shift @_;

	goto \& Test::More::is;
}

sub plan {
	my ($what, $number) = @_;

	@_ = ($what, $number + 1) # had_no_warnings
		unless caller (1);

	goto \& Test::More::plan;
}

sub done_testing {

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	had_no_warnings
		unless caller (1);

	goto \& Test::More::done_testing;
}

sub arrange (&) {
	$_[0]->();
}

*subtest = \& Test::More::subtest;

1;
