
use strict;
use warnings;

use Test::More tests => 25;
use Test::NoWarnings;

use lib 't/lib';

BEGIN {
    use_ok('TMTI::Class::Tank');
    use_ok('TMTI::Class::Car');
}

{
    package Test::MooseX::Types::NonMoose;

    sub new {
        my $class = shift;
        my %args = @_;
        return bless \%args, $class;
    };
    sub breakable {
        my $self = shift;
        if (@_) {
            $self->{breakable} = shift;
        }
        return $self->{breakable};
    }
    sub meta {
        my $self = shift;
        return { pacakge => 'Test::MooseX::Types::NonMoose' };
    }
}
{
    package Test::MooseX::Types::Implements;
    use Moose;
    use MooseX::Types::Moose qw( ArrayRef );
    use MooseX::Types::Implements qw( Implements );
    use TMTI::MyTypes qw( Breakable BreakableDriveable );

    has 'breakable' => (
        is => 'rw',
        isa => Implements[qw(TMTI::Breakable)],
    );

    has 'mybreakable' => (
        is => 'rw',
        isa => Breakable,
    );

    has 'arrayofbreakable' => (
        is => 'rw',
        isa => ArrayRef[Implements[qw(TMTI::Breakable)]],
        traits  => ['Array'],
        handles => {
            add_breakable => 'push',
        },
    );

    has 'arrayofmybreakable' => (
        is => 'rw',
        isa => ArrayRef[Breakable],
        traits  => ['Array'],
        handles => {
            add_mybreakable => 'push',
        },
    );

    has 'breakable_driveable' => (
        is => 'rw',
        isa => Implements[qw( TMTI::Breakable TMTI::Driveable)],
    );

    has 'mybreakable_driveable' => (
        is => 'rw',
        isa => BreakableDriveable,
    );

    eval {
        has 'breakable_non_role' => (
            is => 'rw',
            isa => Implements[qw(TMTI::NonRole)],
        );
    };
    Test::More::like($@, qr/'TMTI::NonRole' is not a Moose::Role/,
        "only Moose::Role is accepted parameter"
    );

    eval {
        has 'breakable_non_existent_role' => (
            is => 'rw',
            isa => Implements[qw(TMTI::Non::Existent::RoleName)],
        );
    };
    Test::More::ok($@, "...and dies if package cannot be loaded");


}

ok my $o = Test::MooseX::Types::Implements->new(),
    "test object created";
ok my $nm = Test::MooseX::Types::NonMoose->new(),
    "non-moose test object created";

eval {
    $o->breakable( 123 );
};
like($@, qr/Object '123' does not implement required role/,
    "Int is not an Object");

eval {
    $o->breakable( [qw( 123 456 )] );
};
like($@, qr/Object '.*?' does not implement required role/,
    "ArrayRef is not an Object");

eval {
    $o->breakable( { k1 => 'v1', k2 => 'v2' } );
};
like($@, qr/Object '.*?' does not implement required role/,
    "HashRef is not an Object");

eval {
    $o->breakable( $nm );
};
like($@, qr/Object '.*?' does not implement required role/,
    "Non-Moose objects are not supported");


my $tank = TMTI::Class::Tank->new();
isa_ok($tank, 'TMTI::Class::Tank');

my $car = TMTI::Class::Car->new();
isa_ok($car, 'TMTI::Class::Car');

ok $o->breakable( $car ),
    "Car implements Breakable interface";

ok $o->mybreakable( $car ),
    "...and subtyping works";

ok $o->add_breakable( $car ),
    "Car can be pushed to ArrayRef, as it implements Breakable interface";

ok $o->add_mybreakable( $car ),
    "...and subtyping works";

ok $o->breakable_driveable( $car ),
    "Car implements both Breakable and Driveable interfaces";

ok $o->mybreakable_driveable( $car ),
    "...and subtyping works";

eval {
    $o->breakable( $tank );
};
like($@, qr/Object '.*?' does not implement required role/,
    "Tank does not implement Breakable interface");

eval {
    $o->mybreakable( $tank );
};
like($@, qr/Object '.*?' does not implement TMTI::Breakable/,
    "...and subtyping works");

eval {
    $o->add_breakable( $tank );
};
like($@, qr/Object '.*?' does not implement required role/,
    "Tank cannot be pushed to ArrayRef, as it does not implement Breakable interface");

eval {
    $o->add_mybreakable( $tank );
};
like($@, qr/Object '.*?' does not implement TMTI::Breakable/,
    "...and subtyping works");

eval {
    $o->breakable_driveable( $tank );
};
like($@, qr/Object '.*?' does not implement required role/,
    "Tank does not implement both Breakable and Driveable interfaces");

eval {
    $o->mybreakable_driveable( $tank );
};
like($@, qr/Object '.*?' does not implement both TMTI::Breakable and TMTI::Driveable/,
    "...and subtyping works");

