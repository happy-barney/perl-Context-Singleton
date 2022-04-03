
use strict;
use warnings;

use require::relative "test-helper.pl";

ok "singleton Contrive::Class should not exist yet"
	=> got    => does_singleton_exist ('Sample::Context::Singleton::Contrive::Class')
	;

contrive_class "Sample::Context::Singleton::Contrive::Class";

it "should resolve known class singleton (Sample::Context::Singleton::Contrive::Class)"
	=> got    => sub { deduce "Sample::Context::Singleton::Contrive::Class" }
	=> expect => "Sample::Context::Singleton::Contrive::Class"
	;

it "should load class dynamically"
	=> got    => sub { Sample::Context::Singleton::Contrive::Class->foo }
	=> expect => "C:C:foo called"
	;

contrive_class "Foo::Bar";

it "shouldn't resolve unknown class singleton (Foo::Bar)"
	=> got    => sub { deduce "Foo::Bar" }
	=> throws => re (qr/Can't locate Foo.Bar.pm/)
	;

had_no_warnings;

done_testing;
