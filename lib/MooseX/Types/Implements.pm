use strict;
use warnings;
package MooseX::Types::Implements;
#ABSTRACT: Require objects to implement a role/interface

use Class::MOP;
use Class::Load;
use MooseX::Types::Moose qw( Object RoleName ArrayRef );
use Moose::Util::TypeConstraints;

use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types -declare =>[qw(
    _Implements
)];
require Moose;

use Sub::Exporter -setup => { exports => [ qw(Implements _Implements) ] };

subtype _Implements,
    as Parameterizable[Object,ArrayRef[RoleName]],
    where {
        my ($object, $roles) = @_;

        for my $role ( @$roles ) {
            return 0 unless
                ( Class::MOP::class_of($object) || return)->does_role( $role );
        }

        return 1;
    },
    message {
        "Object '$_' does not implement required role(s)"
    };

# coerce from RoleName to ArrayRef[RoleName]
# and load required roles, so they could be validated via RoleName
sub Implements {
    my @roles = @{ $_[0] };
    shift @_;

    for my $role ( @roles ) {
        Class::Load::load_class($role);

        # need to check it here, otherwise a cryptic error message will pop
        # out, eg:
        # Validation failed for 'ArrayRef[RoleName]' with value ARRAY(0x2097bd8)
        Moose->throw_error("'$role' is not a Moose::Role")
            unless is_RoleName($role);
    }

    @_ = ( [ \@roles ], @_ );
    goto &_Implements;
}

=head1 SYNOPSIS

    package My::Class;

    use Moose;
    use MooseX::Types::Implements qw( Implements );

    has 'vehicle' => (
        is => 'rw',
        isa => Implements[qw( My::Interfaces::Driveable )],
    );

    has 'pet_animal' => (
        is => 'rw',
        isa => Implements[qw( My::Interfaces::Pet My::Interfaces::Animal )],
    );

Interfaces definitions:

    package My::Interfaces::Driveable;
    use Moose::Role;

    requires qw( drive stop );


    package My::Interfaces::Pet;
    use Moose::Role;

    requires qw( play obey );


    package My::Interfaces::Animal;
    use Moose::Role;

    requires qw( eat sleep roam );

Classes:

    package My::Car;
    use Moose;
    with qw( My::Interfaces::Driveable );

    sub drive { ... };
    sub stop { ... };


    package My::Bicycle;
    use Moose;
    with qw( My::Interfaces::Driveable );

    sub drive { ... };
    sub stop { ... };


    package My::TimeMachine;
    use Moose;

    sub teleport { ... };


    package My::Dog;
    use Moose;
    with qw( My::Interfaces::Pet My::Interfaces::Animal );

    sub play { ... };
    sub obey { ... };

    sub eat { ... };
    sub sleep { ... };
    sub roam { ... };


    package My::Skunk;
    use Moose;
    with qw( My::Interfaces::Animal );

    sub eat { ... };
    sub sleep { ... };
    sub roam { ... };

And finally:

    package main;

    my $class = My::Class->new();

    # My::Car and My::Bicycle implement My::Interfaces::Driveable
    $class->vehicle( My::Car->new() );
    $class->vehicle( My::Bicycle->new() );

    # throws error - you cannot drive TimeMachine
    $class->vehicle( My::TimeMachine->new() );


    # dog is a Pet and an Animal
    $class->pet_animal( My::Dog->new() );

    # throws error - Skunk is an Animal, but not really a Pet
    $class->pet_animal( My::Skunk->new() );

=head1 DESCRIPTION

This class provides parameterizable polymorphic type constraint.

=type Implements

    # single role
    has 'vehicle' => (
        is => 'rw',
        isa => Implements[qw( My::Interfaces::Driveable )],
    );

    # all roles need to be implemented
    has 'pet_animal' => (
        is => 'rw',
        isa => Implements[qw( My::Interfaces::Pet My::Interfaces::Animal )],
    );

C<Implements> is a parameterizable type constraint that requires C<Objects> to
implement specified roles (automatically loaded).

Subtyping is also supported:

    package My::Types;
    use MooseX::Types::Implements qw( Implements );
    use MooseX::Types -declare => [qw(
        Driveable
    )];

    subtype Driveable,
        as Implements[qw( My::Interfaces::Driveable )],
        message {
            "Object '$_' needs to implement My::Interfaces::Driveable"
        };

    package My::Class;
    use Moose;
    use My::Types qw( Driveable );

    has 'vehicle' => (
        is => 'rw',
        isa => Driveable,
    );

=head1 SEE ALSO

L<MooseX::Types::Parameterizable>

L<MooseX::Types>

=cut


1;
