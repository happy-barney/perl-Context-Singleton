
use strict;
use warnings;

use FindBin;
use lib map "${FindBin::Bin}/$_", qw[ ../lib lib sample ];

use Test::Spec::Util;

use Examples::Context::Singleton::Frame::Builder;
use Sample::Context::Singleton::Frame::Builder::Base;

use Context::Singleton::Frame::Builder::Hash;

class_under_test 'Context::Singleton::Frame::Builder::Hash';

my $SAMPLE_BUILDER = 'Sample::Context::Singleton::Frame::Builder::Base::__::Builder';
my $EXAMPLE_CLASS = 'Example::Test::Builder::Base';
my $EXAMPLE_DEDUCE = 'example-deduce';

sub build_args {
    Compare::Builder::Hash::Args->new (@_);
}

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

describe 'Builder::Hash' => as {
    context 'with empty dependencies' => as {
        context "without 'this'" => sub {
            build_instance [
                dep => { },
            ];

            plan tests => 4;

            expect_required   expect => [ ];
            expect_unresolved expect => [ ];
            expect_dep        expect => { };
            expect_build_args expect => [ ];

            return;
        };

        context "with class" => sub {
            build_instance [
                class => $EXAMPLE_CLASS,
                dep => { },
            ];

            plan tests => 4;

            expect_required   expect => [ $EXAMPLE_CLASS ];
            expect_unresolved expect => [ $EXAMPLE_CLASS ];
            expect_dep        expect => { };
            expect_build_args expect => [ $SAMPLE_BUILDER ],
                with_deduced => { with_deduced },
                ;

            return;
        };

        context "with deduce" => sub {
            build_instance [
                deduce => $EXAMPLE_DEDUCE,
                dep => { },
            ];

            plan tests => 4;

            expect_required   expect => [ $EXAMPLE_DEDUCE ];
            expect_unresolved expect => [ $EXAMPLE_DEDUCE ];
            expect_dep        expect => { };
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
                dep => { a => 'foo', b => 'bar' },
            ];

            plan tests => 4;

            expect_required   expect => [ 'foo', 'bar' ];
            expect_unresolved expect => [ 'foo', 'bar' ];
            expect_dep        expect => { a => 'foo', b => 'bar' };
            expect_build_args expect => build_args (a => 'Foo', b => 'Bar'),
                with_deduced => { with_deduced },
                ;

            return;
        };

        return;
        context "with class" => sub {
            build_instance [
                class => $EXAMPLE_CLASS,
                dep => { 'foo', 'bar' },
            ];

            plan tests => 4;

            expect_required   expect => [ $EXAMPLE_CLASS, 'foo', 'bar' ];
            expect_unresolved expect => [ $EXAMPLE_CLASS, 'foo', 'bar' ];
            expect_dep        expect => { 'foo', 'bar' };
            expect_build_args expect => [ $SAMPLE_BUILDER, 'Foo', 'Bar' ],
                with_deduced => { with_deduced },
                ;

            return;
        };

        context "with deduce" => sub {
            build_instance [
                deduce => $EXAMPLE_DEDUCE,
                dep => { 'foo', 'bar' },
            ];

            plan tests => 4;

            expect_required   expect => [ $EXAMPLE_DEDUCE, 'foo', 'bar' ];
            expect_unresolved expect => [ $EXAMPLE_DEDUCE, 'foo', 'bar' ];
            expect_dep        expect => { 'foo', 'bar' };
            expect_build_args expect => [ obj_isa ($SAMPLE_BUILDER), 'Foo', 'Bar' ],
                with_deduced => { with_deduced },
                ;

            return;
        };

        return;
    };
    return;
};


it "should pass" => as {
    cmp_deeply(
        [ xxx => foo => 'bar' ],
        build_args (xxx => foo => 'bar'),
    );
};

done_testing;

package Compare::Builder::Hash::Args;
use parent 'Test::Deep::Cmp';

sub init {
    my $self = shift;

    $self->{cmp_this} = shift if @_ % 2;
    $self->{cmp_val}  = { @_ };
}

sub descend {
    my ($self, $got) = @_;
    my @got_val = @$got;
    my $got_this = shift @got_val if @got_val % 2;

    my ($ok, $stack) = (1);
    ($ok, $stack) = Test::Deep::descend ($got_this, $self->{cmp_this})
        if exists $self->{cmp_this};

    my $hash_got = { @got_val };
    ($ok, $stack) = Test::Deep::descend ($hash_got, $self->{cmp_val})
        if $ok;

    $self->{cmp_diag} = Test::Deep::deep_diag ($stack)
        if $stack;

    $ok;
}

__END__

