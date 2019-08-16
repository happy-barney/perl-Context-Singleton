
use strict;
use warnings;

package Context::Singleton::Rule;

use Moo;

use Ref::Util qw[ is_plain_arrayref ];

use namespace::clean;

has name        => (
	is          => 'ro',
);

has _params     => (
	is          => 'ro',
	init_arg    => undef,
	default     => sub { +{} },
);

has _triggers   => (
	is          => 'ro',
	init_arg    => undef,
	default     => sub { +[] },
);

has _builders   => (
	is          => 'ro',
	init_arg    => undef,
	default     => sub { +[] },
);

has default_builder => (
	is          => 'rw',
	init_arg    => undef,
	lazy        => 1,
	default     => sub {
		$_[0]->default_builder (Context::Singleton::Frame::Builder::Value->new (
			value => $_[0]->default,
		));
	},
);

has env_builder => (
	is          => 'rw',
	init_arg    => undef,
	lazy        => 1,
	default     => sub {
		$_[0]->default_builder (Context::Singleton::Frame::Builder::Value->new (
			value => $ENV{$_[0]->env},
		));
	},
);

sub BUILD {
	my ($self, $args) = @_;

	$self->set (%$args);
}

sub add_builder {
	my ($self, @builders) = @_;

	push @{ $self->_builders },
		grep defined,
		map { is_plain_arrayref ($_) ? @$_ : $_ }
		@builders;
	;

	return $self;
}

sub add_trigger {
	my ($self, @triggers) = @_;

	push @{ $self->_triggers },
		grep defined,
		map { is_plain_arrayref ($_) ? @$_ : $_ }
		@triggers
	;

	return $self;
}

sub builders {
	my ($self) = @_;

	my @builders = @{ $self->_builders };
	push @builders, $self->env_builder
		if $self->has_env && exists $ENV{$self->env};
	push @builders, $self->default_builder if $self->has_default;

	return @builders;
}

sub default {
	$_[0]->param ('default');
}

sub has_default {
	$_[0]->has_param ('default');
}

sub env {
	$_[0]->param ('env');
}

sub has_env {
	$_[0]->has_param ('env');
}

sub has_param {
	my ($self, $name) = @_;

	return exists $self->_params->{$name};
}

sub param {
	my ($self, $name) = @_;

	return $self->_params->{$name};
}

sub set {
	my ($self, %new_params) = @_;

	delete $new_params{name};

	$self->add_builder (delete $new_params{builder});
	$self->add_trigger (delete $new_params{trigger});

	if (%new_params) {
		my $current_params = $self->_params;

		die "Cannot replace defined parameter $_"
			for grep exists $current_params->{$_}, keys %$current_params;

		%{ $current_params } = (%{ $current_params }, %new_params );
	}

	return $self;
}

sub triggers {
	my ($self) = @_;

	return @{ $self->_triggers };
}

1;
