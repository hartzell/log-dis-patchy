
# a stubby little LDO class, just stashes the arguments that were passed to
# new so that we can check them later
# (see Log::Dispatch::Output perldoc)
package LDO;
use Log::Dispatch::Output;
use base qw(Log::Dispatch::Output);

our %args_to_ldo_new;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %p     = @_;
    my $self  = bless {}, $class;

    $self->_basic_init(%p);
    $self->{args_to_ldo_new} = \%p;
    $self->{messages}        = [];
    return $self;
}

sub log_message {
    my $self = shift;
    my %rest = @_;
    push( @{ $self->{messages} }, \%rest );
}
sub messages { return $_[0]->{messages} }

sub reset_messages {
    my @m = @{ $_[0]->{messages} };
    @{ $_[0]->{messages} } = ();
    return \@m;
}

1;
