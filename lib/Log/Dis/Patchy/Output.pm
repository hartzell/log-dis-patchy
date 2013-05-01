package Log::Dis::Patchy::Output;

# ABSTRACT: Easy canned Log::Dispatch::Output configurations

use Moo::Role;

use Class::Load qw(load_class);
use MooX::Types::MooseLike::Base qw(HashRef InstanceOf Str);

has ldo_max_level    => ( is => 'lazy', isa => Str, );
has ldo_min_level    => ( is => 'lazy', isa => Str, );
has ldo_name         => ( is => 'lazy', isa => Str, );
has ldo_package_name => ( is => 'lazy', isa => Str, );

sub _build_ldo_max_level {'emergency'}
sub _build_ldo_min_level {'debug'}

has ldo_init_args => ( is => 'lazy', isa => HashRef, );

sub _build_ldo_init_args {
    my $self = shift;
    return {
        name      => $self->ldo_name,
        max_level => $self->ldo_max_level,
        min_level => $self->ldo_min_level,
    };
}

has output => (
    is  => 'lazy',
    isa => InstanceOf ['Log::Dispatch::Output'],
);

sub _build_output {
    my $self = shift;

    load_class( $self->ldo_package_name )
        or die "Unable to load " . $self->ldo_package_name;

    return $self->ldo_package_name->new( %{ $self->ldo_init_args } );
}

requires qw(_build_ldo_package_name _build_ldo_name);

no Moo::Role;
1;
