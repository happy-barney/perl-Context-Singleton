
use strict;
use warnings;

use FindBin;
use lib map "${FindBin::Bin}/$_", qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton::Frame::Builder;
use Sample::Context::Singleton::Frame::Builder::Base;

use Context::Singleton::Frame::Builder::Array;

class_under_test 'Context::Singleton::Frame::Builder::Array';

my $SAMPLE_BUILDER = 'Sample::Context::Singleton::Frame::Builder::Base::__::Builder';
my $EXAMPLE_CLASS = 'Example::Test::Builder::Base';
my $EXAMPLE_DEDUCE = 'example-deduce';

sub with_dependencies {
	+( 'foo', 'bar' )
}

sub with_deduced {
	+(
		foo => 'Foo',
		bar => 'Bar',
		$EXAMPLE_CLASS => $SAMPLE_BUILDER,
		$EXAMPLE_DEDUCE => bless {}, $SAMPLE_BUILDER,
	);
}

describe 'Builder::Array' => as {
	context 'with empty dependencies' => as {
		context "without 'this'" => sub {
			build_instance [
				dep => [ ],
			];

			plan tests => 4;

			expect_required   expect => [ ];
			expect_unresolved expect => [ ];
			expect_dep        expect => [ ];
			expect_build_args expect => [ ];

			return;
		};

		context "with class" => sub {
			build_instance [
				class => $EXAMPLE_CLASS,
				dep => [ ],
			];

			plan tests => 4;

			expect_required   expect => [ $EXAMPLE_CLASS ];
			expect_unresolved expect => [ $EXAMPLE_CLASS ];
			expect_dep        expect => [ ];
			expect_build_args expect => [ $SAMPLE_BUILDER ],
				with_deduced => { with_deduced },
				;

			return;
		};

		context "with deduce" => sub {
			build_instance [
				deduce => $EXAMPLE_DEDUCE,
				dep => [ ],
			];

			plan tests => 4;

			expect_required   expect => [ $EXAMPLE_DEDUCE ];
			expect_unresolved expect => [ $EXAMPLE_DEDUCE ];
			expect_dep        expect => [ ];
			expect_build_args expect => [ obj_isa ($SAMPLE_BUILDER) ],
				with_deduced => { with_deduced },
				;

			return;
		};

		return;
	};

	context 'with some dependencies' => as {
		context "without 'this'" => sub {
			build_instance [
				dep => [ 'foo', 'bar' ],
			];

			plan tests => 4;

			expect_required   expect => [ 'foo', 'bar' ];
			expect_unresolved expect => [ 'foo', 'bar' ];
			expect_dep        expect => [ 'foo', 'bar' ];
			expect_build_args expect => [ 'Foo', 'Bar' ],
				with_deduced => { with_deduced },
				;

			return;
		};

		context "with class" => sub {
			build_instance [
				class => $EXAMPLE_CLASS,
				dep => [ 'foo', 'bar' ],
			];

			plan tests => 4;

			expect_required   expect => [ $EXAMPLE_CLASS, 'foo', 'bar' ];
			expect_unresolved expect => [ $EXAMPLE_CLASS, 'foo', 'bar' ];
			expect_dep        expect => [ 'foo', 'bar' ];
			expect_build_args expect => [ $SAMPLE_BUILDER, 'Foo', 'Bar' ],
				with_deduced => { with_deduced },
				;

			return;
		};

		context "with deduce" => sub {
			build_instance [
				deduce => $EXAMPLE_DEDUCE,
				dep => [ 'foo', 'bar' ],
			];

			plan tests => 4;

			expect_required   expect => [ $EXAMPLE_DEDUCE, 'foo', 'bar' ];
			expect_unresolved expect => [ $EXAMPLE_DEDUCE, 'foo', 'bar' ];
			expect_dep        expect => [ 'foo', 'bar' ];
			expect_build_args expect => [ obj_isa ($SAMPLE_BUILDER), 'Foo', 'Bar' ],
				with_deduced => { with_deduced },
				;

			return;
		};

		return;
	};
	return;
};

done_testing;

__END__
