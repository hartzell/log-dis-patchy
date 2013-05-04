
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
    return $self;
}
sub log_message { }

1;
