
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

has rule_class => (
	is       => 'ro',
	default  => sub {
		require Context::Singleton::Rule;
		return 'Context::Singleton::Rule';
	},
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

sub _search_rule {
	my ($self, $name) = @_;

	return $self->_rules->{$name};
}

sub _create_rule {
	my ($self, $name) = @_;

	return $self->_rules->{$name} = $self->rule_class->new (name => $name);
}

sub singleton {
	my ($self, $name, @params) = @_;

	my $rule = $self->_search_rule ($name)
		// $self->_create_rule ($name)
		;

	$rule->set (@params)
		if @params;

	return $rule;
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

	my $singleton = $self->singleton ($name);

	return $singleton->set (default => $def{value})
		if exists $def{value};

	my $builder_class = $self->_guess_builder_class (\%def);
	my $builder = $builder_class->new (%def);

	$singleton->add_builder ($builder);

	return;
}

sub trigger {
    my ($self, $name, $trigger) = @_;

	$self
		->singleton ($name)
		->add_trigger ($trigger)
		;

	return;
}

sub find_builder_for {
	my ($self, $name) = @_;

	my $rule = $self->_search_rule ($name);

	return unless $rule;
	return $rule->builders;
}

sub find_trigger_for {
	my ($self, $name) = @_;

	my $rule = $self->_search_rule ($name);

	return unless $rule;
	return $rule->triggers;
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
