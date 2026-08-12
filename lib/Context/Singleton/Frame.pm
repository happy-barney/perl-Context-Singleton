
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
	q ("") => sub { ref ($_[0]) . q ([) . $_[0]->depth . q (]) },
	fallback => 1,
);

has q (_deducer_class)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::Deducer::Notifying:: }
	;

has q (_deducer)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->root_frame->_deducer_class->new (frame => $_[0]) }
	=> handles  => [
		q (is_deduced),
		q (is_deducible),
		q (try_deduce),
	];

has q (db)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->parent ? $_[0]->parent->db : $_[0]->db_class->instance }
	;

has q (db_class)
	=> is       => q (ro)
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::DB:: }
	;

has q (depth)
	=> is       => q (ro)
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { $_[0]->parent ? $_[0]->parent->depth + 1 : 0 }
	;

has q (parent)
	=> is       => q (ro)
	;

has q (root_frame)
	=> is       => q (ro)
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

	use feature q (say);
	say qq (# [${\ $frame->depth}] $sub ${\ join ' ', @message });
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

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Context::Singleton> distribution.

=cut

