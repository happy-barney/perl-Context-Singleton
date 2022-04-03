
use v5.10;
use feature 'state';

use strict;
use warnings;

package Context::Singleton::Frame::DB;

use Moo;

use Class::Load;
use Module::Pluggable::Object;
use Ref::Util;

use Context::Singleton::Frame::Builder::Value;
use Context::Singleton::Frame::Builder::Hash;
use Context::Singleton::Frame::Builder::Array;

use namespace::clean;

has 'cache'
	=> is       => 'ro'
	=> init_arg => +undef
	=> default  => sub { +{} }
	;

has 'triggers'
	=> is       => 'ro'
	=> init_arg => +undef
	=> default  => sub { +{} }
	;

has 'plugins'
	=> is       => 'ro'
	=> init_arg => +undef
	=> default  => sub { +{} }
	;

sub BUILD {
	my ($self) = @_;

	$self->contrive ('Class::Load', (
		value => 'Class::Load',
	));

	$self->contrive ('class_loader', (
		dep => [ 'Class::Load' ],
		as  => sub { $_[0]->can ('load_class') },
	));
}

sub instance {
	state $instance = __PACKAGE__->new;
	return $instance;
}

sub contrive_class {
	my ($self, $name) = @_;

	return if exists $self->cache->{$name};

	$self->contrive ($name, (
		dep => [ 'class_loader' ],
		as => eval "sub { \$_[0]->(q[$name]) && q[$name] }",
	));

	return;
}

sub _guess_builder_class {
	my ($self, $def) = @_;

	return 'Context::Singleton::Frame::Builder::Value' if exists $def->{value};
	return 'Context::Singleton::Frame::Builder::Hash'  if Ref::Util::is_hashref ($def->{dep});
	return 'Context::Singleton::Frame::Builder::Array'
}

sub contrive {
	my ($self, $name, %def) = @_;

	if ($def{class}) {
		$self->contrive_class ($def{class});
		$def{builder} //= 'new';
	}

	if ($def{class} // $def{deduce}) {
		$def{this} = $def{class} // $def{deduce};
		delete $def{class};
		delete $def{deduce};
	}

	my $builder_class = $self->_guess_builder_class (\%def);
	my $builder = $builder_class->new (%def);

	push @{ $self->cache->{ $name } }, $builder;

	return;
}

sub trigger {
	my ($self, $name, $code) = @_;

	push @{ $self->triggers->{ $name } }, $code;

	return;
}

sub find_builder_for {
	my ($self, $name) = @_;

	return @{ $self->cache->{ $name } // [] };
}

sub find_trigger_for {
	my ($self, $name) = @_;

	return @{ $self->triggers->{ $name } // [] };
}

sub load_rules {
	my ($self, @packages) = @_;

	for my $package (@packages) {
		$self->plugins->{ $package } //= do {
			Module::Pluggable::Object->new (
				require => 1,
				search_path => [ $package ],
			)->plugins;
			1;
		};
	}

	return;
}

1;
