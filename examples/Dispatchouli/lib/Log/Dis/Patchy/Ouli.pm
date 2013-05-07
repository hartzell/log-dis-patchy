
package Log::Dis::Patchy::Ouli;

use namespace::autoclean;
use Moo;
with qw(Log::Dis::Patchy Log::Dis::Patchy::Ouli::QuietFatal);

use Log::Dis::Patchy::Helpers qw(prepend_pid_callback);
use MooX::Types::MooseLike::Base qw(AnyOf Bool Str Undef);

has to_self   => ( is => 'ro', isa => Bool, default => 0 );
has to_stdout => ( is => 'ro', isa => Bool, default => 0 );
has to_stderr => ( is => 'ro', isa => Bool, default => 0 );
has facility => ( is => 'ro', isa => AnyOf [ Str, Undef ], );
has to_file => ( is => 'ro', isa => Bool, default => 0 );
has log_file => ( is => 'ro', isa => Str, );
has log_path => ( is => 'ro', isa => Str, );

has log_pid => ( is => 'ro', isa => Bool, default => 0 );

sub _build_debug {
    my $self = shift;
    $self->env_value('DEBUG');
}

sub _build_outputs {
    my $self = shift;
    my @outputs;

    push( @outputs, 'Log::Dis::Patchy::Ouli::Self' )   if $self->to_self;
    push( @outputs, 'Log::Dis::Patchy::Ouli::Stdout' ) if $self->to_stdout;
    push( @outputs, 'Log::Dis::Patchy::Ouli::Stderr' ) if $self->to_stderr;
    push( @outputs, 'Log::Dis::Patchy::Ouli::Syslog' )
        if $self->facility and not $self->env_value('NOSYSLOG');
    push( @outputs, 'Log::Dis::Patchy::Ouli::File' ) if $self->to_file;

    return \@outputs;
}

sub _build_callbacks {
    my $self = shift;
    my @callbacks;
    push( @callbacks, prepend_pid_callback() ) if $self->log_pid;
    return \@callbacks;
}

sub env_prefix { return; }

sub env_value {
    my ( $self, $suffix ) = @_;

    my @path = grep {defined} ( $self->env_prefix, 'DISPATCHOULI' );

    for my $prefix (@path) {
        my $name = join q{_}, $prefix, $suffix;
        return $ENV{$name} if defined $ENV{$name};
    }

    return;
}

has '+failure_is_fatal' => ( init_arg => 'fail_fatal' );
sub fail_fatal { my $self = shift; return $self->failure_is_fatal(@_); }

sub is_debug { my $self = shift; return $self->debug(); }

sub set_prefix { my $self = shift; return $self->prefix(@_); }

sub events       { my $self = shift; return $self->messages() }
sub clear_events { my $self = shift; return $self->reset_messages() }

sub dispatcher { my $self = shift; return $self->_dispatcher }

sub new_tester {
    my ( $class, $arg ) = @_;
    $arg ||= {};

    return $class->new(
        {   ident   => "$$:$0",
            log_pid => 0,
            %$arg,
            to_stderr => 0,
            to_stdout => 0,
            to_file   => 0,
            to_self   => 1,
            facility  => undef,
        }
    );
}

1;
