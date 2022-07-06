
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame::Builder::Base;

use List::Util v1.450;
use Moo;

use namespace::clean;

has '_default'
	=> is       => 'ro'
	=> init_arg => 'default'
	=> default  => sub { +{} }
;

has 'this'
	=> is       => 'ro'
	;

has 'dep'
	=> is       => 'ro'
	;

has 'as'
	=> is       => 'ro'
	=> predicate => 'has_as'
	;

has 'call'
	=> is       => 'ro'
	=> predicate => 'has_call'
	;

has 'builder'
	=> is       => 'ro'
	=> predicate => 'has_builder'
	;

has '_required'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { [ List::Util::uniq $_[0]->_build_required ] }
	;

sub _build_required {
	my ($self) = @_;

	return grep defined, $self->this;
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
		if $self->has_as;

	my $this = shift @args;

	return $this->can ($self->call)->(@args)
		if $self->has_call;

	return $this->${\ $self->builder } (@args);
}

sub build_callback_args {
	my ($self, $resolved) = @_;

	return map $resolved->{$_}, grep $_, $self->this;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame::Builder::Base - Base class for argument builders

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

