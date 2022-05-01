#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use require::relative "test-helper.pl";

plan tests => 4;

my $root = current_frame;

it "root should not have a parent"
	=> got    => current_frame->parent
	=> expect => undef
	;

frame {
	it "child frame report root as a parent"
		=> got    => current_frame->parent
		=> expect => shallow ($root)
		;

	my $child_frame = current_frame;
	frame {
		it "another child frame should report its parent"
			=> got    => current_frame->parent
			=> expect => shallow ($child_frame)
			;
	};
};

had_no_warnings;

done_testing;
