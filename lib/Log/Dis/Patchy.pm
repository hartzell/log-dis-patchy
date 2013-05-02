package Log::Dis::Patchy;

# ABSTRACT: Easy way to build your own Log::Dispatch wrapper

=head1 SYNOPSIS

TODO

=head1 DESCRIPTION

TODO

=cut

use Moo::Role;

use namespace::autoclean;

use Class::Load qw(load_class);
use Data::OptList;
use Log::Dispatch;
use MooX::Types::MooseLike::Base
    qw(AnyOf ArrayRef Bool CodeRef ConsumerOf Enum InstanceOf Str Undef);
use Params::Util qw(_ARRAY0 _HASH0 _CODELIKE);
use Try::Tiny;

=attr callbacks

A lazy arrayref of coderefs, added to the L<Log::Dispatch> object when it is
created.  Override/modify L</_build_callbacks> to provide your own defaults.

Callbacks are passed a hash containing the following keys:

    ( message => $log_message, level => $log_level )

and are expected to modify the message and then return a single scalar
containing that modified message.

See L<Log::Dispatch/CONSTRUCTOR> for more details.

See L<Log::Dis::Patchy::Helpers> for some helpful callback generators.

=method _build_callbacks

Builder for L</callbacks>.  Returns a reference to an empty array.
Override/modify to provide your desired set of default callbacks.

=cut

has callbacks => ( is => 'lazy', isa => ArrayRef [CodeRef], );
sub _build_callbacks { [] }

=attr config_id

A lazy string, the name for this loggers config.  Rarely needed.  See
L</_build_config_id>.

=method _build_config_id

Builder for L</config_id>.  Returns the value of the L</ident> attribute.
Override/modify to supply a different default.

=cut

has config_id => (
    is  => 'lazy',
    isa => Str,
);
sub _build_config_id { return $_[0]->ident }

=attr debug

A read-write boolean attribute, defaults to 0, that controls debug logging.
Set it to 1 enable logging via log_debug, set it to 0 to quietly drop log_debug
messages.

=cut

has debug => ( is => 'rw', isa => Bool, default => 0 );

=attr failure_is_fatal

A read-write boolean attribute, defaults to 1, that controls whether to die if
logging a messages fails.

=cut

has failure_is_fatal => ( is => 'rw', isa => Bool, default => 1 );

=attr flogger

A lazy string, the name of the package used to flog messages before they are
passed to L<Log::Dispatch>.

The package is automatically loaded via L<Class::Load/load_class>.

See </_build_flogger>.

=method _build_flogger

Builder for L</flogger>.  Returns 'String::Flogger'.  Override/modify it to
provide a different default.

=cut

has flogger => (
    is     => 'lazy',
    isa    => Str,
    coerce => sub { load_class( $_[0] ) or die "Unable to load " . $_[0] }
);
sub _build_flogger {'String::Flogger'}

=attr ident

A required readonly string, the name of the thing logging.

=cut

has ident => ( is => 'ro', isa => Str, required => 1, );

=attr muted

A boolean attribute, defaults to 0, that enables temporarily silencing logging.
Set to 1 to mute.  See L</mute> and L</unmute>.

=method mute

Sets L</mute> to 1.

=method unmute

Sets L</mute> to 0.

=cut

has muted => ( is => 'rw', isa => Bool, default => 0 );
sub mute   { $_[0]->muted(1) }
sub unmute { $_[0]->muted(0) }

=attr outputs

Information used to configure the set of outputs that are added to the
underlying L<Log::Dispatch> object.

It is an arrayref of arrayrefs, each inner array ref contains two scalars: a
package name and a hashref of init_args for that package.  E.g.

  [ [ AnOutput => { an_arg => 1 } ], [ OtherOutput => {} ] ]

In the name of brevity and laziness, this attribute is coerced via
L<Data::OptList/mkopt>.  The above example could be written as:

  [ AnOutput => { an_arg => 1 }, 'OtherOutput' ]

And really simple configurations only require the package names:

  [ qw( AnOutput AnotherOutput ) ]

Packages are loaded using L<Class::Load/load_class> and passed any supplied
init_args on instantiation.

See </_build_outputs>.

=cut

has outputs => (
    is     => 'lazy',
    isa    => ArrayRef [ArrayRef],
    coerce => sub { Data::OptList::mkopt( $_[0], { moniker => 'outputs' } ) },
);

=attr prefix

Either a coderef or string used to prefix the log message.  A coderef is called
with the message string as its only argument and is expected to return a
string.  String prefixes are prepended the message string.

See L<_build_prefix>.

=method clear_prefix

Moo-provided clearer for L</prefix>.

=cut

has prefix => (
    is      => 'rw',
    isa     => AnyOf [ CodeRef, Str, Undef ],
    clearer => 1,
);

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
sub _build_quiet_fatal { return ['stderr']; }

=attr _dispatcher

Private.  Hands off.  "This is not the method you're looking for.  Move along."

A lazy C<InstanceOf['Log::Dispatch']> holds the L<Log::Dispatch> object to
which messages are sent.

=method _build__dispatcher

Builder for L</_dispatcher>.  Creates a new L<Log::Dispatch> instance; loads,
instantiates, and adds the contents of L</_outputs> to the dispatcher's set of
outputs and adds the contents of L<_callback> to the dispatcher's callbacks
list.

=cut

has _dispatcher => (
    is       => 'lazy',
    isa      => InstanceOf ['Log::Dispatch'],
    init_arg => undef,
);

sub _build__dispatcher {
    my $self       = shift;
    my $dispatcher = Log::Dispatch->new();

    for my $po ( @{ $self->_patchy_outputs } ) {
        my $output = $po->output;    # grab the Log::Dispatch::Output instance

        die "Output names must be unique, found duplicates: " . $output->name
            if ( $dispatcher->output( $output->name ) );

        $dispatcher->add($output);
    }

    $dispatcher->add_callback($_) for ( @{ $self->callbacks } );

    return $dispatcher;
}

=attr _output_objs

Private.  Hands off.  Go away kid.

An arrayref of L<Log::Dis::Patchy::Output> consuming classes.  Used to build
L<_dispatcher> and as a stash of the classes that provided the
L<Log::Dispatch::Output> instances, e.g. for L</messages>.

=cut

has _patchy_outputs => (
    is  => 'lazy',
    isa => ArrayRef [ ConsumerOf ['Log::Dis::Patchy::Output'] ],
);

sub _build__patchy_outputs {
    my $self = shift;
    my $outputs;

    for my $aref ( @{ $self->outputs } ) {
        my $package_name = $aref->[0];
        my $init_args = $aref->[1] || {};

        load_class($package_name)
            or die "Unable to load class: $package_name";

        push @$outputs, $package_name->new($init_args); # patchy output object

    }
    return $outputs;
}

=method log

Log a message.

If the first argument is a hashref it is used as a set of options.  Valid
options include:

=for :list
level  - Level at which to log the message.  Defaults to 'info'.
prefix - A prefix, as described in L</prefix>.

Remaining arguments are flogged (see L</flogger>) and joined into a single
string (see L</_join>).  Each prefix is applied to the message (see
L</prefix>).

Almost, but not quite verbatim from Log::Dispatchouli.

=cut

sub log {
    my ( $self, @rest ) = @_;
    my $opt = _HASH0( $rest[0] ) ? shift(@rest) : {};

    my $message;

    if ( $opt->{fatal} or not $self->muted ) {
        try {
            my @flogged = map { $self->flogger->flog($_) } @rest;

            $message = join q{ }, @flogged;

            my $prefix
                = _ARRAY0( $opt->{prefix} )
                ? $opt->{prefix}
                : [ $opt->{prefix} ];

            for ( reverse grep {defined} $self->prefix, @$prefix ) {
                if ( _CODELIKE($_) ) {
                    $message = $_->($message);
                }
                else {
                    $message =~ s/^/$_/gm;
                }
            }

            $self->_dispatcher->log(
                level => $opt->{level} || 'info',
                message => $message,
            );
        }
        catch {
            $message = '(no message could be logged)' unless defined $message;
            die $_ if $self->{failure_is_fatal};
        };
    }

    die $message if $opt->{fatal};

    return;
}

=method log_debug

Log a debug message.  A no-op unless L</debug> evaluates to a true value.

If the first argument is a hashref it is taken to be a set of options.  In
addition to the options that L</log> accepts, valid options include:

=for :list
level - level at which to log the message, defaults to 'debug'.

Verbatim from Log::Dispatchouli.

=cut

sub log_debug {
    my ( $self, @rest ) = @_;

    return unless $self->debug;

    my $opt = _HASH0( $rest[0] ) ? shift(@rest) : {};   # for future expansion

    local $opt->{level} = defined $opt->{level} ? $opt->{level} : 'debug';

    $self->log( $opt, @rest );
}

=method log_fatal

Log a fatal message.

If the first argument is a hashref it is taken to be a set of options.  In
addition to the options that L</log> accepts, valid options include:

=for :list
level - level at which to log the message, defaults to 'error'.
fatal - make message fatal, defaults to 1.

Verbatim from Log::Dispatchouli.

=cut

sub log_fatal {
    my ( $self, @rest ) = @_;

    my $opt = _HASH0( $rest[0] ) ? shift(@rest) : {};   # for future expansion

    local $opt->{level} = defined $opt->{level} ? $opt->{level} : 'error';
    local $opt->{fatal} = defined $opt->{fatal} ? $opt->{fatal} : 1;

    $self->log( $opt, @rest );
}

=method message

TODO use a role instead of can....

Returns an arrayref of log messages by walking across the set of output objects
and snarfing from any that maintain a stash.

See L</reset_messages>.

=cut

sub messages {
    my $self = shift;

    my @messages = map { @{ $_->messages } }
        grep { $_->can('messages') } @{ $self->_patchy_outputs };

    return \@messages;
}

=method reset_messages

TODO use a role instead of can.

Walks across the set of output objects and resets (empties) the stashes of any
output objects that maintain one.

See L</messages>.

=cut

sub reset_messages {
    my $self = shift;
    $_->reset_messages
        for grep { $_->can('reset_messages') } @{ $self->patchy_outputs };

    return;
}

has _proxy_package => (
    is       => 'lazy',
    init_arg => undef,
    coerce   => sub { load_class( $_[0] ) or die "Unable to load " . $_[0] }
);
sub _build__proxy_package {'Log::Dis::Patchy::Proxy'}

sub proxy {
    my $self = shift;
    my $opt = shift || {};

    my $p = $self->_proxy_package->new(
        {   logger => $self,
            %{$opt},
        }
    );
    return $p;
}

=requires _build_outputs

Builder for L</outputs>, returns a reference to the information described in
L</outputs>.

=cut

requires qw(_build_outputs);

1;
