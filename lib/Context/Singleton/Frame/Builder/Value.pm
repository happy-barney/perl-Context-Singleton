
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Value;

use Moo;

use namespace::clean;

BEGIN { extends 'Context::Singleton::Frame::Builder::Base' }

has 'value'
	=> is       => 'ro'
	;

sub build {
	my ($self) = @_;

	return $self->value;
}

1;

