package Log::Dis::Patchy::QuietFatal;

use namespace::autoclean;
use Moo::Role;

use MooX::Types::MooseLike::Base qw( ArrayRef Enum );

=attr quiet_fatal

TODO.  Currently unused....

A lazy C<ArrayRef> containing zero, one, or both of the strings 'stdout' and
'stderr'.  Listed outputs will not receive fatal log messages.  Will coerce
single scalar values into an C<ArrayRef>.  See L<_build_quiet_fatal>.

See L</_build_quiet_fatal>.

=method _build_quiet_fatal

Builder for L</quiet_fatal>.  Returns C<['stderr']>.

=cut

has quiet_fatal => (
    is     => 'lazy',
    isa    => ArrayRef [ Enum [ 'stdout', 'stderr' ] ],
    coerce => sub { _ARRAY0( $_[0] ) ? $_[0] : [ $_[0] ] },
);

sub _build_quiet_fatal {    ## no critic(ProhibitUnusedPrivateSubroutines)
    return ['stderr'];
}

1;
