
use feature 'state';

use strict;
use warnings;

package Context::Singleton::Frame::DB;

use Moo;

use Module::Pluggable::Object;
use Ref::Util;

use Context::Singleton::Frame::Builder::Value;
use Context::Singleton::Frame::Builder::Hash;
use Context::Singleton::Frame::Builder::Array;

has _rules      => (
	is          => 'ro',
	init_arg    => undef,
	default     => sub { +{} },
);

has _plugins    => (
	is          => 'ro',
	init_arg    => undef,
	default     => sub { +{} },
);

has _triggers   => (
	is          => 'ro',
	init_arg    => undef,
	default     => sub { +{} },
);

use namespace::clean;

sub BUILD {
	my ($self) = @_;

	$self->contrive ('Context::Singleton::Class::Load', (
		as => sub { require Class::Load; 'Class::Load' },
	));

	$self->contrive ('Context::Singleton::Class::Load->load_class', (
		value => 'load_class',
	));

	$self->contrive ('Context::Singleton->load_class', (
		dep => [
			'Context::Singleton::Class::Load',
			'Context::Singleton::Class::Load->load_class',
		],
		as  => sub { $_[0]->can ($_[1]) },
	));
}

sub instance {
	# TODO: role Context::Singleton::Role::Instance
	state $instance = __PACKAGE__->new;

	return $instance;
}

sub contrive_class {
	my ($self, $name) = @_;

	unless (exists $self->_rules->{$name}) {
		$self->contrive ($name, (
			dep => [ 'Context::Singleton->load_class' ],
			as => eval "sub { \$_[0]->(q[$name]) && q[$name] }",
		));
	}
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

	push @{ $self->_rules->{ $name } }, $builder;

	return;
}

sub trigger {
	my ($self, $name, $code) = @_;

	push @{ $self->_triggers->{ $name } }, $code;

	return;
}

sub find_builder_for {
	my ($self, $name) = @_;

	return @{ $self->_rules->{ $name } // [] };
}

sub find_trigger_for {
	my ($self, $name) = @_;

	return @{ $self->_triggers->{ $name } // [] };
}

sub load_rules {
	my ($self, @packages) = @_;

	for my $package (@packages) {
		$self->_plugins->{ $package } //= do {
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
