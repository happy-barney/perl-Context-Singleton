
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Base;

use List::Util v1.450;

sub new {
	my ($class, %params) = @_;

	$params{default} //= {};

	my $self = bless \%params, $class;

	$self->{required} = [ List::Util::uniq $self->_build_required ];

	return $self;
}

sub _build_required {
	my ($self) = @_;

	return grep defined, $self->this;
}

sub this {
	$_[0]->{this};
}

sub _default {
	$_[0]->{default};
}

sub _required {
	$_[0]->{required};
}

sub as {
	$_[0]->{as};
}

sub call {
	$_[0]->{call};
}

sub builder {
	$_[0]->{builder};
}

sub dep {
	$_[0]->{dep};
}

sub required {
	my ($self) = @_;

	return @{ $self->_required };
}

sub unresolved {
	my ($self, $resolved) = @_;
	my $default = $self->_default;
	$resolved //= {};

	return
		grep ! exists $default->{$_},
		grep ! exists $resolved->{$_},
		$self->required
		;
}

sub default {
	my ($self) = @_;

	return %{ $self->_default };
}

sub build {
	my ($self, $resolved) = @_;

	$resolved = { %{ $self->_default }, %{ $resolved // {} } };
	my @args = $self->build_callback_args ($resolved);

	return $self->as->(@args)
		if $self->as;

	my $this = shift @args;

	return $this->can ($self->call)->(@args)
		if $self->call;

	return $this->${\ $self->builder } (@args);
}

sub build_callback_args {
	my ($self, $resolved) = @_;

	return map $resolved->{$_}, grep $_, $self->this;
}

1;

