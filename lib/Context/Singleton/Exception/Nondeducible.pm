
use strict;
use warnings;

package Context::Singleton::Exception::Nondeducible;

use Exception::Class ( __PACKAGE__ );

sub new {
	my ($self, $rule) = @_;

	$self->SUPER::new (error => "Cannot deduce: $rule");
}

1;

