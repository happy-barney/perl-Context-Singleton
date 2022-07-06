
use v5.10;
use strict;
use warnings;
use feature 'state';

package Context::Singleton;

use parent 'Exporter::Tiny';

use Context::Singleton::Frame;

our @EXPORT = (
	qw[ contrive        ],
	qw[ current_frame   ],
	qw[ deduce          ],
	qw[ frame           ],
	qw[ is_deduced      ],
	qw[ load_rules      ],
	qw[ proclaim        ],
	qw[ trigger         ],
	qw[ try_deduce      ],
);

sub _exported_accessors {
	my ($globals) = @_;
	my $frame_class = $globals->{frame_class} // 'Context::Singleton::Frame';

	state %cache;

	return $cache{$frame_class} //= do {
		my $current_frame = "\$Context::Singleton::__::${frame_class}::current_frame";
		eval "$current_frame = $frame_class->build_frame";

		+{
			contrive      => eval "sub { $current_frame->contrive (\@_) }",
			current_frame => eval "sub { $current_frame }",
			deduce        => eval "sub { $current_frame->deduce (\@_) }",
			frame         => eval "sub (&) { local $current_frame = $current_frame->build_frame; \$_[0]->(); };",
			is_deduced    => eval "sub { $current_frame->is_deduced (\@_) }",
			load_rules    => eval "sub { $current_frame->load_rules (\@_) }",
			proclaim      => eval "sub { $current_frame->proclaim (\@_) }",
			trigger       => eval "sub { $current_frame->trigger (\@_) }",
			try_deduce    => eval "sub { $current_frame->try_deduce (\@_) }",
		};
	};
}

sub _exporter_expand_sub {
	my ($class, $name, $args, $globals) = @_;

	return $name => _exported_accessors ($globals)->{$name};
}

sub _exporter_validate_opts {
   my ($class, $globals) = @_;

   $class->SUPER::_exporter_validate_opts(@_);

   _exported_accessors ($globals)->{load_rules}->(@{ $globals->{load_path} // [] })
	   if $globals->{load_path};
}

1;

__END__

=head1 NAME

Context::Singleton - handles context specific singletons

=head1 DESCRIPTION

=head2 What is a context specific singleton?

As your workflow handles its tasks, granularity become finer and certain
entities behaves like singletons.

Nice example is user id/object after successful authentication.
Its value is constant for every function/method called after it is known
but is unknown and can represents millions of users.

=head2 How does it differ from the multiton pattern?

Multiton is a set of singletons (global variables) whereas Context::Singleton
provides context scope.

=head2 Doesn't C<local> already provide similar behaviour?

Context::Singleton doesn't provide only localized scope.

It provides immutability on scope and can build values based on dependencies.
With dependency tracking it can rebuild them in inner scope in case their
dependencies were modified.

=head1 EXPORTED FUNCTIONS

=head2 Terms

=head3 resource

Singleton idenfication, string, global.

=head3 recipe

Rule specifies how to build value

	contrive 'resource' => ( ... );

There can be multiple recipes for building a C<singleton value>.
The one with most relevant dependencies (those proclaimed in the deepest frame)
will be used.
If there are more available recipes, the first defined will be used.

Refer L<#contrive> for more.

=head3 frame

Frame represents hierarchy.

Resource values are by default cached in the top-most frame providing all their
dependencies.

Cached values are destroyed upon leaving context.

=head1 EXPORTED FUNCTIONS

Context singleton exports the following functions by default.

=head2 frame CODE

	frame {
		...;
	}

Creates a new frame. Its argument behaves like a function and it returns its
return value. It preserves list/scalar context when calling CODE.

=head2 proclaim resource => value, ...;

	proclaim resource => value;
	proclaim resource => value, resource2 => value2;

Define the value of a resource in the current context.

The resource's value in a given frame can be defined only once.

Returns the value of the last resource in the argument list.

=head2 deduce

	my $var = deduce 'resource';

Makes and returns a resource value available in current frame.

If resource value is not available, it tries to build it using known recipes
or looks into parent frames (using deepest = best).

=head2 load_path

	load_path 'prefix-1', ...;

Evaluate all modules within given module prefix(es).
Every prefix is evaluated only once.

=head2 contrive

Defines new receipt how to build resource value

	contrive 'name' => (
		class => 'Foo::Bar',
		deduce => 'rule_object',
		builder => 'new',
		default => { rule_1 => 'v1', ... },
		dep => [ 'rule_2', ... ],
		dep => { param_a => 'rule_1', ... },
		as => sub { ... },
		value => 10,
	);

=over

=item value => constant

Simplest rule, just constant value.

=item as => CODEREF

Defines code used to build resource value. Dependencies are passed as arguments.

=item builder => method_name

Specifies builder method name to be used by C<class> or C<deduce>.
Defaults to C<new>.

=item class => Class::Name

Calls the builder method with dependencies on the given class to build a value.
Automatically creates a rule with the given class name using
a default builder providing dynamic load.

Behaves essentially like

	eval "use Class::Name";
	Class::Name->$builder (@deps);

=item deduce => rule_name

Calls the builder method (with dependencies) on the object available
as a value of the given rule.

Behaves essentially like

	my $object = deduce ('rule_name');
	$object->$builder (@deps);

=item default

Default values of dependencies. If used they are treated as deduced in root context but
not stored nor cached anywhere.

=item dep

Dependencies required to deduce this rule.

Two forms are recognized at the moment:

=over

=item ARRAYREF

List of required rules.
Passed as a list to the builder function

=item HASHREF

Hash values are treated as rule names.
Passed as a list of named parameters to the builder function.

=back

=back

=head1 TUTORIAL

See short tutorial L<Context::Singleton::Tutorial>

