
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame::Deducer;

use Moo;

use namespace::clean;

has 'frame'
	=> is       => 'ro'
	=> weak_ref => 1
	=> handles  => [
		'depth',
		'db',
	];

sub parent {
	my ($deducer) = @_;

	return unless $deducer->frame->parent;
	return $deducer->frame->parent->_deducer;
}

1;
