package Log::Dis::Patchy::Proxy;

# ABSTRACT: Proxy object for Log::Dis::Patchy.

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=cut

use Moo;

use MooX::StrictConstructor;
use namespace::autoclean;

use MooX::Types::MooseLike::Base
    qw(AnyOf Bool CodeRef ConsumerOf InstanceOf Str);
use Params::Util qw(_ARRAY0 _HASH0);

=attr parent

A required attribute, either a L<Log::Dis::Patchy> consuming class (e.g. a
logger) or another L<Log::Dis::Patchy::Proxy> object.

=method messages

Delegated to $self->parent->messages by L<Moo>.

=method reset_messages

Delegated to $self->parent->reset_messages by L<Moo>.

=method ident

Delegated to $self->parent->ident by L<Moo>.

=method config_id

Delegated to $self->parent->config_id by L<Moo>.

=cut

has parent => (
    is  => 'ro',
    isa => AnyOf [
        ConsumerOf ['Log::Dis::Patchy'],
        InstanceOf ['Log::Dis::Patchy::Proxy'],
    ],
    required => 1,
    handles  => [qw(messages reset_messages ident config_id)],
);

=attr prefix

See L<Log::Dis::Patchy/prefix>.

=cut

has prefix => (
    is      => 'rw',
    isa     => AnyOf [ CodeRef, Str ],
    clearer => 1,
);

=attr proxy_prefix

A proxy specific prefix, read-only.  See L<Log::Dis::Patchy/prefix> for general
information about prefixes.

=cut

has proxy_prefix => (
    is  => 'ro',
    isa => AnyOf [ CodeRef, Str ],
);

=method _get_all_prefixes

Private.  Go away.  No finger-pokin'!

Gathers all of the various prefixes together into a single arrayref.

Nearly a clone of Log::Dispatchouli::Proxy::_get_all_prefix.

=cut

sub _get_all_prefixes {
    my ( $self, $arg ) = @_;

    return [
        $self->proxy_prefix, $self->prefix,
        _ARRAY0( $arg->{prefix} ) ? @{ $arg->{prefix} } : $arg->{prefix}
    ];
}

=attr debug

A read-write boolean attribute that controls whether L</log_debug> logs
messages.  See L<Log::Dis::Patchy/debug>.

This attribute does a song-and-dance to maintain a local copy of the attribute
if it has ever been explicitly set while returning the parent value if the
local copy has never been set or has been cleared.  See L</debug>,
L</get_local_debug>, L</set_local_debug>, L</clear_local_debug> and
L<has_local_debug>.

=method get_local_debug

Moo-built "getter" for the L</debug> attribute.

=method set_local_debug

Moo-built "setter" for the L</debug> attribute.

=method clear_local_debug

Moo-built "clearer" for the L</debug> attribute.

=method has_local_debug

Moo-built "predicate" for the L</debug> attribute.

=method debug

Sets and returns the proxy's debug information if passed an argument.

Gets the proxy's debug information if it exists (been set and never been
cleared).

Gets the parents debug information otherwise.

=cut

has debug => (
    is        => 'rw',
    isa       => Bool,
    reader    => 'get_local_debug',
    writer    => 'set_local_debug',
    clearer   => 1,
    predicate => 'has_local_debug',
);

sub debug {
    my ( $self, @args ) = @_;
    return $self->set_local_debug(@args) if @args;
    return $self->get_local_debug() if $self->has_local_debug;
    return $self->parent->debug();
}

=attr muted

A read-write boolean attribute that temporarily silences non-fatal logging.
See L<Log::Dis::Patchy/muted>.

This attribute does a song-and-dance to maintain a local copy of the attribute
if it has ever been explicitly set while returning the parent value if the
local copy has never been set or has been cleared.  See L</muted>,
L</get_local_muted>, L</set_local_muted>, L</clear_local_muted> and
L<has_local_muted>.

=method get_local_muted

Moo-built "getter" for the L</muted> attribute.

=method set_local_muted

Moo-built "setter" for the L</muted> attribute.

=method clear_local_muted

Moo-built "clearer" for the L</muted> attribute.

=method has_local_muted

Moo-built "predicate" for the L</muted> attribute.

=method muted

Sets and returns the proxy's muted information if passed an argument.

Gets the proxy's muted information if it exists (been set and never been
cleared).

Gets the parents muted information otherwise.

=cut

has muted => (
    is        => 'rw',
    isa       => Bool,
    reader    => 'get_local_muted',
    writer    => 'set_local_muted',
    clearer   => 1,
    predicate => 'has_local_muted',
);

sub muted {
    my ( $self, @args ) = @_;
    return $self->set_local_muted(@args) if @args;
    return $self->get_local_muted() if $self->has_local_muted;
    return $self->parent->muted();
}

=method mute

Sets L</muted> to 1.

=method unmute

Sets L</muted> to 0.

=cut

sub mute   { my $self = shift; return $self->muted(1) }
sub unmute { my $self = shift; return $self->muted(0) }

=method log

Logs a message.  See L<Log::Dis::Patchy/log>.  If the first argument is a
hashref it is taken to be a hashref of options.

A no-op if $self->muted is true and it is not a fatal message.

Almost a clone of L<Log::Dispatchouli::Proxy/log>.

=cut

sub log {    ## no critic(ProhibitBuiltinHomonyms)
    my ( $self, @rest ) = @_;
    my $opt = _HASH0( $rest[0] ) ? shift(@rest) : {};

    return if $self->muted and not $opt->{fatal};

    local $opt->{prefix} = $self->_get_all_prefixes($opt);

    return $self->parent->log( $opt, @rest );
}

=method log_fatal

Logs a fatal message.  See L<Log::Dis::Patchy/log_fatal>.  If the first
argument is a hashref it is taken to be a hashref of options.

Almost a clone of L<Log::Dispatchouli::Proxy/log_fatal>.

=cut

sub log_fatal {
    my ( $self, @rest ) = @_;

    my $opt = _HASH0( $rest[0] ) ? shift(@rest) : {};
    local $opt->{fatal} = 1;

    return $self->log( $opt, @rest );
}

=method log_debug

Logs a debug message.  See L<Log::Dis::Patchy/log_debug>.  If the first
argument is a hashref it is taken to be a hashref of options.

A no-op if $self->debug is true.

Almost a clone of L<Log::Dispatchouli::Proxy/log_debug>.

=cut

sub log_debug {
    my ( $self, @rest ) = @_;

    return unless $self->debug;

    my $opt = _HASH0( $rest[0] ) ? shift(@rest) : {};
    local $opt->{level} = 'debug';

    return $self->log( $opt, @rest );
}

=head1 SEE ALSO

=for :list
* L<Log::Dispatchouli>
* L<Log::Dispatch>
* L<MooX::StrictConstructor>

=cut

1;
