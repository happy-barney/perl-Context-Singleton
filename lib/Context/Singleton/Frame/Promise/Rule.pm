
use strict;
use warnings;

package Context::Singleton::Frame::Promise::Rule;

use Moo;

use namespace::clean;

BEGIN { extends 'Context::Singleton::Frame::Promise' }

use namespace::clean;

has 'rule'
	=> is       => 'ro'
	;

sub notify_deducible {
	my ($self, $in_depth) = @_;

	$self->set_deducible ($in_depth)
		if $self->deducible_dependencies;
}

sub deducible_builder {
	my ($self) = @_;

	for my $dependency ($self->deducible_dependencies) {
		next unless $dependency->deduced_in_depth == $self->deduced_in_depth;

		return $dependency;
	}
}

1;

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame::Promise::Rule - Represents all rules of one singleton

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

