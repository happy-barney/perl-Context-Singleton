
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Value;

use parent qw[ Context::Singleton::Frame::Builder::Base ];

sub new {
	my ($class, %def) = @_;

	return $class->SUPER::new (value => $def{value});
}

sub value {
	$_[0]->{value};
}

sub build {
	my ($self) = @_;

	return $self->value;
}

1;

