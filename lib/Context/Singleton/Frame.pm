
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame;

use Moo;

use Context::Singleton::Frame::DB;
use Context::Singleton::Exception::Invalid;
use Context::Singleton::Exception::Deduced;
use Context::Singleton::Exception::Nondeducible;
use Context::Singleton::Frame::Deducer::Notifying;

use namespace::clean;

use overload (
	'""' => sub { ref ($_[0]) . '[' . $_[0]->depth . ']' },
	fallback => 1,
);

has '_deducer_class'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::Deducer::Notifying:: }
	;

has '_deducer'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->root_frame->_deducer_class->new (frame => $_[0]) }
	=> handles  => [
		'is_deduced',
		'is_deducible',
		'try_deduce',
	];

has 'db'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->parent ? $_[0]->parent->db : $_[0]->db_class->instance }
	;

has 'db_class'
	=> is       => 'ro'
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::DB:: }
	;

has 'depth'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->parent ? $_[0]->parent->depth + 1 : 0 }
	;

has 'parent'
	=> is       => 'ro'
	;

has 'root_frame'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->parent ? $_[0]->parent->root_frame : $_[0] }
	;

sub build_frame {
	my ($class, %proclaim) = @_;

	my $frame = $class->new (
		(parent => $class) x !! ref $class,
	);

	$frame->proclaim (%proclaim);

	return $frame;
}

sub debug {
	my ($frame, @message) = @_;

	my $sub = (caller(1))[3];
	$sub =~ s/^.*://;

	use feature 'say';
	say "# [${\ $frame->depth}] $sub ${\ join ' ', @message }";
}

sub _frame_by_depth {
	my ($frame, $depth) = @_;

	return if $depth < 0;

	my $distance = $frame->depth - $depth;
	return if $distance < 0;

	my $found = $frame;

	$found = $found->parent
		while $distance-- > 0;

	$found;
}

sub _throw_deduced {
	my ($frame, $singleton) = @_;

	throw Context::Singleton::Exception::Deduced ($singleton);
}

sub _throw_nondeducible {
	my ($frame, $singleton) = @_;

	throw Context::Singleton::Exception::Nondeducible ($singleton);
}

sub contrive {
	my ($frame, $singleton, @how) = @_;

	$frame->db->contrive ($singleton, @how);
}

sub load_rules {
	shift->db->load_rules (@_);
}

sub trigger {
	shift->db->trigger (@_);
}

sub deduce {
	my ($frame, $singleton, @proclaim) = @_;

	$frame = $frame->new (@proclaim) if @proclaim;

	$frame->_throw_nondeducible ($singleton)
		unless $frame->try_deduce ($singleton);

	$frame->_deducer->deduce ($singleton);
}

sub proclaim {
	my ($frame, @proclaim) = @_;

	return unless @proclaim;

	my $retval;
	while (@proclaim) {
		my $singleton = shift @proclaim;
		my $value = shift @proclaim;

		$frame->_throw_deduced ($singleton)
			if $frame->is_deduced ($singleton);

		$retval = $frame->_deducer->proclaim ($singleton, $value);
	}

	$retval;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Context::Singleton::Frame - Internal representation of Context::Singleton's frame

=head1 DESCRIPTION

This is internal package.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

