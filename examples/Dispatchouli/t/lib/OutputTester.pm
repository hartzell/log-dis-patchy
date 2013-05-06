
package OutputTester;

use Test::Roo::Role;

use Log::Dispatchouli;
use Log::Dis::Patchy::Ouli;
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef InstanceOf Str);
use Test::Deep;

has init_args => ( is => 'ro', isa => HashRef, );

has interesting_keys => ( is => 'ro', isa => ArrayRef, );

has output_name => ( is => 'ro', isa => Str );

has ouli_logger => (
    is  => 'lazy',
    isa => InstanceOf ['Log::Dispatchouli'],

);

sub _build_ouli_logger {
    my $self = shift;
    return Log::Dispatchouli->new( $self->init_args );
}

has patchy_logger => (
    is  => 'lazy',
    isa => InstanceOf ['Log::Dis::Patchy::Ouli'],
);

sub _build_patchy_logger {
    my $self = shift;
    return Log::Dis::Patchy::Ouli->new( $self->init_args );
}

test 'ouli and patchy match(y...)' => sub {
    my $self = shift;

    my $name = $self->output_name;
    my $ouli_dispatcher_output
        = $self->ouli_logger->dispatcher->output($name);
    my $patchy_dispatcher_output
        = $self->patchy_logger->dispatcher->output($name);

    $DB::single = 1 if ($name eq 'logfile');
    my @ouli_info
        = map { $ouli_dispatcher_output->{$_} } @{ $self->interesting_keys };
    my @patchy_info
        = map { $patchy_dispatcher_output->{$_} }
        @{ $self->interesting_keys };

    cmp_deeply( \@ouli_info, \@patchy_info,
        'values for interesting keys match' );

};

1;
