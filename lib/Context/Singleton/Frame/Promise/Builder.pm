
use strict;
use warnings;

package Context::Singleton::Frame::Promise::Builder;

use Moo;

use namespace::clean;

BEGIN { extends 'Context::Singleton::Frame::Promise' }

has 'builder'
	=> is       => 'ro'
	;

sub notify_deducible {
	my ($self, $in_depth) = @_;

	$self->set_deducible ($in_depth)
		if $self->deducible_dependencies == $self->dependencies;
}

1;

