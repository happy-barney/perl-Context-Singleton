
use v5.10;
use strict;
use warnings;

package Context::Singleton::Frame;

use Moo;

use Context::Singleton::Frame::DB;
use Context::Singleton::Exception::Invalid;
use Context::Singleton::Exception::Deduced;
use Context::Singleton::Exception::Nondeducible;
use Context::Singleton::Frame::Promise;
use Context::Singleton::Frame::Promise::Builder;
use Context::Singleton::Frame::Promise::Rule;

use namespace::clean;

use overload (
	'""' => sub { ref ($_[0]) . '[' . $_[0]->depth . ']' },
	fallback => 1,
);

has '_class_builder_promise'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::Promise::Builder:: }
	;

has '_class_rule_promise'
	=> is       => 'ro'
	=> init_arg => +undef
	=> lazy     => 1
	=> default  => sub { Context::Singleton::Frame::Promise::Rule:: }
	;

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

has 'promises'
	=> is       => 'ro'
	=> init_arg => +undef
	=> default  => sub { +{} }
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

sub _build_builder_promise_for {
	my ($frame, $builder) = @_;

	my $promise = $frame->_class_builder_promise->new (
		depth   => $frame->depth,
		builder => $builder,
	);

	my %optional = $builder->default;
	my %required = map +($_ => 1), $builder->required;
	delete @required{ keys %optional };

	$promise->add_dependencies (
		map $frame->_search_promise_for ($_), keys %required
	);

	$promise->set_deducible (0) unless keys %required;

	$promise->listen ($frame->_search_promise_for ($_))
		for keys %optional;

	$promise;
}

sub _build_rule_promise_for {
	my ($frame, $singleton) = @_;

	$frame->promises->{$singleton} // do {
		my $promise = $frame->promises->{$singleton} = $frame->_class_rule_promise->new (
			depth => $frame->depth,
			rule => $singleton,
		);

		$promise->add_dependencies ($frame->parent->_search_promise_for ($singleton))
			if $frame->parent;

		for my $builder ($frame->db->find_builder_for ($singleton)) {
			$promise->add_dependencies (
				$frame->_build_builder_promise_for ($builder)
			);
		}

		$promise;
	};
}

sub _deduce_rule {
	my ($frame, $singleton) = @_;

	my $promise = $frame->_search_promise_for( $singleton );
	return $promise->value if $promise->is_deduced;

	my $builder_promise = $promise->deducible_builder;
	return $builder_promise->value if $builder_promise->is_deduced;

	my $builder = $builder_promise->builder;
	my %deduced = $builder->default;

	for my $dependency ($builder->required) {
		# dependencies with default values may not be deducible
		# relying on promises to detect deducible values
		next unless $frame->is_deducible( $dependency );

		$deduced{$dependency} = $frame->deduce ($dependency);
	}

	$builder->build (\%deduced);
}

sub _execute_triggers {
	my ($frame, $singleton, $value) = @_;

	$_->($value) for $frame->db->find_trigger_for ($singleton);
}

sub _find_promise_for {
	my ($frame, $singleton) = @_;

	$frame->promises->{$singleton};
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

sub _search_promise_for {
	my ($frame, $singleton) = @_;

	$frame->_find_promise_for ($singleton)
		// $frame->_build_rule_promise_for ($singleton)
		;
}

sub _set_promise_value {
	my ($frame, $promise, $value) = @_;

	$promise->set_value ($value, $frame->depth);
	$frame->_execute_triggers ($promise->rule, $value);

	$value;
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

	$frame->_find_promise_for ($singleton)->value;
}

sub is_deduced {
	my ($frame, $singleton) = @_;

	return unless my $promise = $frame->_find_promise_for ($singleton);
	return $promise->is_deduced;
}

sub is_deducible {
	my ($frame, $singleton) = @_;

	return unless my $promise = $frame->_search_promise_for ($singleton);
	return $promise->is_deducible;
}

sub proclaim {
	my ($frame, @proclaim) = @_;

	return unless @proclaim;

	my $retval;
	while (@proclaim) {
		my $key = shift @proclaim;
		my $value = shift @proclaim;

		my $promise = $frame->_find_promise_for ($key)
			// $frame->_build_rule_promise_for ($key)
			;

		$frame->_throw_deduced ($key)
			if $promise->is_deduced;

		$retval = $frame->_set_promise_value ($promise, $value);
	}

	$retval;
}

sub try_deduce {
	my ($frame, $singleton) = @_;

	my $promise = $frame->_search_promise_for ($singleton);
	return unless $promise->is_deducible;

	my $value = $frame
		->_frame_by_depth ($promise->deduced_in_depth)
		->_deduce_rule ($promise->rule)
		;

	$promise->set_value ($value, $promise->deduced_in_depth);

	1;
}

1;

__END__

