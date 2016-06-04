
use strict;
use warnings;
use feature 'state';

package Context::Singleton;

our $VERSION = v1.0.0;

use Sub::Install qw();
use Sub::Name qw();
use Variable::Magic qw();

use Context::Singleton::Frame;

sub _install_and_rename {
    my (%params) = @_;

    Sub::Install::install_sub (\%params);
    Sub::Name::subname "$params{into}::$params{as}" => $params{code};
}

use namespace::clean;

sub import {
    my (undef, %params) = @_;

    warnings->import;
    strict->import;

    my ($stack, $package) = (0);

    while (my ($caller, undef, undef, $sub) = caller ($stack++)) {
        last unless $sub =~ m/::import$/;
        $package = $caller;
    }

    $params{resolver_class} //= 'Context::Singleton::Frame';
    $params{load_path} //= [ ];
    $params{with_import} //= 0;

    state $current_context = $params{resolver_class}->new;

    # localize lexical variable
    my $restore_context_wizard = Variable::Magic::wizard (
        free => sub { $current_context = $current_context->parent; 1 },
    );

    my $frame = sub (&) {
        Variable::Magic::cast my $guard => $restore_context_wizard;
        $current_context = $current_context->new;

        $_[0]->();
    };

    my $load_rules  = sub { $current_context->db->load_rules (@_) };
    my $trigger     = sub { $current_context->db->trigger (@_) };
    my $proclaim    = sub { $current_context->proclaim (@_) };
    my $try_deduce  = sub { $current_context->try_deduce (@_) };
    my $deduce      = sub { $current_context->deduce (@_) };
    my $is_deduced  = sub { $current_context->is_deduced (@_) };
    my $contrive    = sub { $current_context->db->contrive (@_) };

    my $prefix = '';
    $prefix = $params{prefix} . '_' if $params{prefix};

    _install_and_rename (into => $package, as => "${prefix}load_rules",  code => $load_rules);
    _install_and_rename (into => $package, as => "${prefix}trigger",     code => $trigger);
    _install_and_rename (into => $package, as => "${prefix}frame",       code => $frame);
    _install_and_rename (into => $package, as => "${prefix}proclaim",    code => $proclaim);
    _install_and_rename (into => $package, as => "${prefix}deduce",      code => $deduce);
    _install_and_rename (into => $package, as => "${prefix}try_deduce",  code => $try_deduce);
    _install_and_rename (into => $package, as => "${prefix}is_deduced",  code => $is_deduced);
    _install_and_rename (into => $package, as => "${prefix}contrive",    code => $contrive);

    if ($params{with_import}) {
        my $import = sub { Context::Singleton->import };
        _install_and_rename (into => $package, as => 'import', code => $import);
    }

    $load_rules->(@{ $params{load_path} });
}

1;

__END__

=head1 NAME

Context::Singleton - handles context specific singletons

=head1 DESCRIPTION

=head2 What is context specific singletons?

As your workflow handles its tasks, granularity become finer and certain
entities behaves like singletons.

Nice example is user id/object after successful authentication.
Its value is constant for every function/method called after it is known
but is unknown and can represents millions of users.

=head2 How it differs from Multiton pattern?

Multiton is set of singletons (global variable) whereas Context::Singleton
provides context scope.

=head2 Doesn't C<local> already provide same behaviour?

Context::Singleton doesn't provide only localized scope.

It provides immutability on scope and can build values based on dependencies.
With dependency tracking it can rebuild them in inner scope in case their
dependencies were modified.

=head1 EXPORTED FUNCTIONS

=head2 Terms

=head3 resource

Singleton idenfication, string, global.

=head3 receipt

Rule specifies how to build value

  contrive 'resource' => ( ... );

There can me multiple receipts how to build C<singleton value>.
One with most precious dependencies (proclaimed in deepest frame) is used.
If there are more, first defined is used.

Refer L<#contrive> for more.

=head3 frame

Frame represents hierarchy.

Resource values are by default cached in top-most frame providing their
dependencies.

It destroys cached values on leaving context.

=head1 EXPORTED FUNCTIONS

Context singleton exports following function by default.

=head2 frame CODE

   frame {
      ...;
   }

Creates new frame. It's argument behaves like function and it returns its
return value. It preserves list/scalar context when calling CODE.

=head2 proclaim resource => value, ...;

   proclaim resource => value;
   proclaim resource => value, resource2 => value2;

Define value of resource in current context.

Value in one frame can be defined only once.

Returns value of last resource

=head2 deduce

   my $var = deduce 'resource';

Make and return resource value available in current frame.

If resource value is not available tries to build it using known receipts
or looks into parent frames (using deepest = best).

=head2 load_path

  load_path 'prefix-1', ...;

Evaluate all modules within given module prefixes.
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

=item value

Simplest rule, use constant value.

=item as

Defines code used to build resource value. Dependencies are passed as arguments.

=item class

Calls builder method with dependencies on this class to get value.
Automatically creates rule with class name with default builder providing dynamic load.

Acts like

   eval "use $class";
   $class->$builder (@deps);

=item deduce

Calls builder method with dependencies on object provided by specified rule.

=item builder

Defaults to C<new>, specifies method name to call on C<class>/C<deduce>

=item default

Default values of dependencies. If used they are treated as resolved in root context but
not stored nor cached anywhere.

Default values are treated as resolved in root frame.

=item dep

Dependencies required to deduce this rule.

Two forms are recognized at the moment:

=over

=item ARRAYREF

List of required rules, passed as list to builder function

=item HASHREF

Hash values are treated as rule names. Passed as list of named parameters to builder function.

=back

=back

=head1 TUTORIAL

See short tutorial L<Context::Singleton::Tutorial>

