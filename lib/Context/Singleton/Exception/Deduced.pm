
use strict;
use warnings;

package Context::Singleton::Exception::Deduced;

use Exception::Class ( __PACKAGE__ );

sub new {
	my ($self, $singleton) = @_;

	$self->SUPER::new (error => "Already deduced: $singleton");
}

1;

