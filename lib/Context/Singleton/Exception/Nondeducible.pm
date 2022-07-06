
use strict;
use warnings;

package Context::Singleton::Exception::Nondeducible;

use Exception::Class ( __PACKAGE__ );

sub new {
	my ($self, $singleton) = @_;

	$self->SUPER::new (error => "Cannot deduce: $singleton");
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Exception::Nondeducible - Context::Singleton exception

=head1 DESCRIPTION

This exception is thrown when singleton value cannot be deduced

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

