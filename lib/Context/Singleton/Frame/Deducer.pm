
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame::Deducer;

use Moo;

use namespace::clean;

has q (frame)
	=> is       => q (ro)
	=> weak_ref => 1
	=> handles  => [
		q (depth),
		q (db),
	];

sub parent {
	my ($deducer) = @_;

	return unless $deducer->frame->parent;
	return $deducer->frame->parent->_deducer;
}

1;
