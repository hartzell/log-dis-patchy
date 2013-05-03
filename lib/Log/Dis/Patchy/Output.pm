package Log::Dis::Patchy::Output;

# ABSTRACT: Easy canned Log::Dispatch::Output configurations

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=cut

use namespace::autoclean;

use Moo::Role;

use Class::Load qw(load_class);
use MooX::Types::MooseLike::Base qw(HashRef InstanceOf Str);

=attr ldo_max_level

A lazy string, used to initialize the L<Log::Dispatch::Output> instances
max_level attribute.

=method _build_ldo_max_level

Builder for L</ldo_max_level>, returns 'emergency'.

=cut

has ldo_max_level => ( is => 'lazy', isa => Str, );
sub _build_ldo_max_level {'emergency'}

=attr ldo_min_level

A lazy string, used to initialize the L<Log::Dispatch::Output> instance's
min_level attribute.

=method _build_ldo_min_level

Builder for L</ldo_min_level>, returns 'debug'.

=cut

has ldo_min_level => ( is => 'lazy', isa => Str, );
sub _build_ldo_min_level {'debug'}

=attr ldo_name

A lazy string, used to initialize the L<Log::Dispatch::Output> instance's name.

=cut

has ldo_name => ( is => 'lazy', isa => Str, );

=attr ldo_package_name

A lazy string, the name of the package that defines the specific
L<Log::Dispatch::Output> subclass to instantiate.

Has a coercion that loads the class using L<Class::Load/load_class>.

=cut

has ldo_package_name => (
    is     => 'lazy',
    isa    => Str,
    coerce => sub {
        load_class( $_[0] ) or die "Unable to load " . $_[0];
    },

);

=attr ldo_init_args

A lazy hashref, supplies the arguments used to initialize the
L<Log::Dispatch::Output> subclass named by L</ldo_package_name>.

=method _build_ldo_init_args

Builder for L</ldo_init_args>.  Sets C<name>, C<max_level> and C<min_level>
using attributes supplied by this role.  See L</ldo_name>, L</ldo_max_level>,
L</ldo_min_level>.

=cut

has ldo_init_args => ( is => 'lazy', isa => HashRef, );

sub _build_ldo_init_args {
    my $self = shift;
    return {
        name      => $self->ldo_name,
        max_level => $self->ldo_max_level,
        min_level => $self->ldo_min_level,
    };
}

=attr output

A lazy instance of a L<Log::Dispatch::Output> subclass.

=method _build_output

Builder for L</output>, calls C<new> on the package named by
L</ldo_package_name>, passing it initialization args provided by
L</ldo_init_args>.

=cut

has output => (
    is  => 'lazy',
    isa => InstanceOf ['Log::Dispatch::Output'],
);

sub _build_output {
    my $self = shift;

    my $package = $self->ldo_package_name;
    return $package->new( %{ $self->ldo_init_args } );
}

=requires _build_ldo_name

Builder for L</ldo_name>, must return a name for the L<Log::Dispatch::Output>
subclass instance.

=requires _build_ldo_package_name

Builder for L</ldo_package_name>, must return a name of the package that
defines the L<Log::Dispatch::Output> subclass that will be instantiated.

=cut

requires qw( _build_ldo_name _build_ldo_package_name );

=head1 SEE ALSO

=for :list
* L<Class::Load>
* L<Log::Dispatch>
* L<Log::Dispatch::Output>

=cut

1;
