package Log::Dis::Patchy;

# ABSTRACT: Easy way to build your own Log::Dispatch wrapper

use Moo::Role;

use Class::Load qw(load_class);
use Data::OptList;
use Log::Dispatch;
use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef InstanceOf Str);

has callbacks => ( is => 'lazy', isa => ArrayRef [CodeRef], );

has ident => ( is => 'ro', isa => Str, required => 1, );

has outputs => (
    is     => 'lazy',
    isa    => ArrayRef,
    coerce => sub { Data::OptList::mkopt( $_[0], { moniker => 'outputs' } ) },
);
sub _build_outputs { [] }

=attr _dispatcher

A lazy C<InstanceOf['Log::Dispatch']> holds the L<Log::Dispatch> object to
which messages are sent.

"This is not the method you're looking for.  Move along."

=cut

has _dispatcher => (
    is       => 'lazy',
    isa      => InstanceOf ['Log::Dispatch'],
    init_arg => undef,
);

=method _build__dispatcher

Builder for L</_dispatcher>.  Creates a new L<Log::Dispatch> instance; loads,
instantiates, and adds the contents of L</_outputs> to the dispatcher's set of
outputs and adds the contents of L<_callback> to the dispatcher's callbacks
list.

=cut

sub _build__dispatcher {
    my $self       = shift;
    my $dispatcher = Log::Dispatch->new();

    for my $aref ( @{ $self->outputs } ) {
        my $package_name = $aref->[0];
        my $init_args = $aref->[1] || {};

        load_class($package_name)
            or die "Unable to load class: $package_name";

        my $po     = $package_name->new($init_args);    # patchy output object
        my $output = $po->output;

        die "Output names must be unique, found duplicates: " . $output->name
            if ( $dispatcher->output( $output->name ) );

        $dispatcher->add($output);
    }

    $dispatcher->add_callback($_) for ( @{ $self->callbacks } );

    return $dispatcher;
}

requires qw(_build_outputs);

no Moo::Role;
1;
