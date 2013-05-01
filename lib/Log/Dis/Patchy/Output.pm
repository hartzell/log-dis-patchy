package Log::Dis::Patchy::Output;

use Moo::Role;

use Class::Load qw(load_class);
use MooX::Types::MooseLike::Base qw(Bool HashRef InstanceOf Str);

has ldo_defaults => ( is => 'lazy', isa => HashRef, );
has ldo_package_name => ( is => 'lazy', isa => Str, );
has options => ( is => 'ro', isa => HashRef, default => sub { {} } );

has output => (
    is  => 'lazy',
    isa => InstanceOf ['Log::Dispatch::Output'],
);

sub _build_output {
    my $self = shift;

    load_class( $self->ldo_package_name )
        or die "Unable to load " . $self->ldo_package_name;

    # see Moose::Autobox::Hash::merge...
    my $opts = { %{ $self->ldo_defaults }, %{ $self->options } };
    return $self->ldo_package_name->new( %{$opts} );
}

requires qw(_build_ldo_defaults _build_ldo_package_name);

no Moo::Role;
1;
