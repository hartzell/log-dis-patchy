package Log::Dis::Patchy;

use Moo::Role;

use Class::Load qw(load_class);
use Data::OptList;
use Log::Dispatch;
use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef HashRef InstanceOf);

has callbacks => (
    is      => 'ro',
    isa     => ArrayRef [CodeRef],
    default => sub { [] },
);

has outputs => (
    is     => 'lazy',
    isa    => ArrayRef,
    coerce => sub { Data::OptList::mkopt( $_[0], { moniker => 'yikes' } ) },
);

has ident => ( is => 'ro', required => 1, );

=attr _dispatcher

A lazy C<InstanceOf['Log::Dispatch']> holds the L<Log::Dispatch> object to
which messages are sent.

=method dispatcher

Moo-generated getter for the dispatch object.

"This is not the method you're looking for.  Move along."

=method clear__dispatcher

A Moo-generated clearer for L</_dispatcher>.

=cut

has _dispatcher => (
    is       => 'lazy',
    isa      => InstanceOf ['Log::Dispatch'],
    init_arg => undef,
    clearer  => 1,
);

=method _build__dispatcher

Builder for L</_dispatcher>.  Creates a new L<Log::Dispatch> instance, adds the
contents of L</_outputs> to its set of outputs and adds the contents of
L<_callback> to its callbacks list.

=cut

sub _build__dispatcher {
    my $self       = shift;
    my $dispatcher = Log::Dispatch->new();

    for my $aref ( @{ $self->outputs } ) {
        my $package_name = $aref->[0];
        my $options = $aref->[1] || {};

        load_class($package_name)
            or die "Unable to load class: $package_name";
        my $patchy_output = $package_name->new( { options => $options } );
        my $output = $patchy_output->output;

        if ( $dispatcher->output( $output->name ) ) {
            die "Duplicate outputs named: " . $output->name;
        }

        $dispatcher->add($output);
    }

    for my $callback (@{$self->callbacks}) {
        $dispatcher->add_callback($callback);
    }

    return $dispatcher;
}

requires qw(_build_outputs);

no Moo::Role;
1;
