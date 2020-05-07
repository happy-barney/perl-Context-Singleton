
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Value;

use Moo;

extends 'Context::Singleton::Frame::Builder::Base';

has value => (
	is => 'ro',
);

sub build {
	my ($self) = @_;

	return $self->value;
}

1;

