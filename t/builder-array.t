#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use require::relative "test-helper.pl";

plan tests => 3;

contrive 'dependency'
	=> value    => 'with-dependency'
	;

contrive 'with-array-dependencies'
	=> dep      => [qw[ dependency ]]
	=> as       => sub { [ @_ ] }
	;

contrive 'without-dep'
	=> as       => sub { 'without-dependencies' }
	;

it "should pass resolved dependencies as positional arguments"
	=> got      => sub { deduce 'with-array-dependencies' }
	=> expect   => [ 'with-dependency' ]
	;

it "should not need empty arrayref to deduce subroutine without dependencies"
	=> got      => sub { deduce 'without-dep' }
	=> expect   => 'without-dependencies'
	;

had_no_warnings;

done_testing;
