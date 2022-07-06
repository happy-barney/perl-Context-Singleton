
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Array;

use Moo;

use namespace::clean;

BEGIN { extends 'Context::Singleton::Frame::Builder::Base' }

has 'dep'
	=> is       => 'ro'
	=> default  => sub { +[] }
	;

sub _build_required {
	my ($self) = @_;

	return (
		$self->SUPER::_build_required,
		@{ $self->dep },
	);
}

sub build_callback_args {
	my ($self, $resolved) = @_;

	return (
		$self->SUPER::build_callback_args ($resolved),
		@$resolved{@{ $self->dep }},
	);
}

1;

