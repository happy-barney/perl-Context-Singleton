
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Hash;

use Moo;

use namespace::clean;

BEGIN { extends 'Context::Singleton::Frame::Builder::Base' }

has 'dep'
	=> is       => 'ro'
	=> default  => sub { +{} }
	;

has '_keys'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { [ keys %{ $_[0]->dep } ] }
	;


sub _build_required {
	my ($self) = @_;

	return (
		$self->SUPER::_build_required,
		grep defined, @{ $self->dep }{ @{ $self->_keys } },
	);
}

sub build_callback_args {
	my ($self, $resolved) = @_;

	my $dep = $self->dep;
	return (
		$self->SUPER::build_callback_args ($resolved),
		map +( $_ => $resolved->{$dep->{$_}} ), @{ $self->_keys }
	);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame::Builder::Hash - Build value form hashref dependencies

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

