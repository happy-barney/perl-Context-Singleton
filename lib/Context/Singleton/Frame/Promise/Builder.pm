
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

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame::Promise::Builder - Represents single contrive

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

