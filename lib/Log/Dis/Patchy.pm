package Log::Dis::Patchy;

# ABSTRACT: Easy way to build your own Log::Dispatch wrapper

use Moo::Role;

use Class::Load qw(load_class);
use Data::OptList;
use Log::Dispatch;
use MooX::Types::MooseLike::Base
    qw(AnyOf ArrayRef Bool CodeRef InstanceOf Str);
use Params::Util qw(_ARRAY0 _HASH0);
use Try::Tiny;

has callbacks => ( is => 'lazy', isa => ArrayRef [CodeRef], );

has ident => ( is => 'ro', isa => Str, required => 1, );

has outputs => (
    is     => 'lazy',
    isa    => ArrayRef,
    coerce => sub { Data::OptList::mkopt( $_[0], { moniker => 'outputs' } ) },
);
sub _build_outputs { [] }

has _output_objs => ( is => 'ro', isa => ArrayRef, default => sub { [] } );

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

        my $po = $package_name->new($init_args);    # patchy output object
        push @{ $self->_output_objs }, $po;
        my $output = $po->output;

        die "Output names must be unique, found duplicates: " . $output->name
            if ( $dispatcher->output( $output->name ) );

        $dispatcher->add($output);
    }

    $dispatcher->add_callback($_) for ( @{ $self->callbacks } );

    return $dispatcher;
}

has prefix => (
    is      => 'ro',
    isa     => AnyOf [ CodeRef, Str ],
    clearer => 1,
);

has flogger => (
    is     => 'lazy',
    isa    => Str,
    coerce => sub { load_class( $_[0] ) or die "Unable to load " . $_[0] }
);
sub _build_flogger {'String::Flogger'}

has failure_is_fatal => ( is => 'ro', isa => Bool, default => 1 );
has debug            => ( is => 'ro', isa => Bool, default => 0 );
has muted            => ( is => 'ro', isa => Bool, default => 0 );

# almost, but not quite verbatim from Log::Dispatchouli
sub log {
    my ( $self, @rest ) = @_;
    my $arg = _HASH0( $rest[0] ) ? shift(@rest) : {};

    my $message;

    if ( $arg->{fatal} or not $self->muted ) {
        try {
            my @flogged = map { $self->flogger->flog($_) } @rest;
            $message = join q{ }, @flogged;

            my $prefix
                = _ARRAY0( $arg->{prefix} )
                ? $arg->{prefix}
                : [ $arg->{prefix} ];

            for ( reverse grep {defined} $self->prefix, @$prefix ) {
                if ( _CODELIKE($_) ) {
                    $message = $_->($message);
                }
                else {
                    $message =~ s/^/$_/gm;
                }
            }

            $self->_dispatcher->log(
                level => $arg->{level} || 'info',
                message => $message,
            );
        }
        catch {
            $message = '(no message could be logged)' unless defined $message;
            die $_ if $self->{failure_is_fatal};
        };
    }

    die $message if $arg->{fatal};

    return;
}

# copied verbatim from Log::Dispatchouli
sub log_fatal {
    my ( $self, @rest ) = @_;

    my $arg = _HASH0( $rest[0] ) ? shift(@rest) : {};   # for future expansion

    local $arg->{level} = defined $arg->{level} ? $arg->{level} : 'error';
    local $arg->{fatal} = defined $arg->{fatal} ? $arg->{fatal} : 1;

    $self->log( $arg, @rest );
}

sub log_debug {
    my ( $self, @rest ) = @_;

    return unless $self->debug;

    my $arg = _HASH0( $rest[0] ) ? shift(@rest) : {};   # for future expansion

    local $arg->{level} = defined $arg->{level} ? $arg->{level} : 'debug';

    $self->log( $arg, @rest );
}

sub messages {
    my $self = shift;

    my @messages = map { @{ $_->messages } }
        grep { $_->can('messages') } @{ $self->_output_objs };

    return \@messages;
}

sub reset_messages {
    my $self = shift;
    $_->reset_messages
        for grep { $_->can('reset_messages') } @{ $self->_output_objs };

    return;
}

requires qw(_build_outputs);

no Moo::Role;
1;
