
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
	my ($db) = @_;

	$db->contrive ('Class::Load', (
		value => 'Class::Load',
	));

	$db->contrive ('class_loader', (
		dep => [ 'Class::Load' ],
		as  => sub { $_[0]->can ('load_class') },
	));
}

sub instance {
	state $instance = __PACKAGE__->new;
	return $instance;
}

sub contrive_class {
	my ($db, $name) = @_;

	return if exists $db->cache->{$name};

	$db->contrive ($name, (
		dep => [ 'class_loader' ],
		as => eval "sub { \$_[0]->(q[$name]) && q[$name] }",
	));

	return;
}

sub _guess_builder_class {
	my ($db, $def) = @_;

	return 'Context::Singleton::Frame::Builder::Value' if exists $def->{value};
	return 'Context::Singleton::Frame::Builder::Hash'  if Ref::Util::is_hashref ($def->{dep});
	return 'Context::Singleton::Frame::Builder::Array'
}

sub contrive {
	my ($db, $name, %def) = @_;

	if ($def{class}) {
		$db->contrive_class ($def{class});
		$def{builder} //= 'new';
	}

	if ($def{class} // $def{deduce}) {
		$def{this} = $def{class} // $def{deduce};
		delete $def{class};
		delete $def{deduce};
	}

	my $builder_class = $db->_guess_builder_class (\%def);
	my $builder = $builder_class->new (%def);

	push @{ $db->cache->{ $name } }, $builder;

	return;
}

sub trigger {
	my ($db, $name, $code) = @_;

	push @{ $db->triggers->{ $name } }, $code;

	return;
}

sub search_builder_for {
	my ($db, $name) = @_;

	return @{ $db->cache->{ $name } // [] };
}

sub search_trigger_for {
	my ($db, $name) = @_;

	return @{ $db->triggers->{ $name } // [] };
}

sub load_rules {
	my ($db, @packages) = @_;

	for my $package (@packages) {
		$db->plugins->{ $package } //= do {
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

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::DB - Internal class storing singleton rules.

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

