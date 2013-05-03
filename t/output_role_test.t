#!perl

use Test::Roo;

use lib qw(t/lib);
use Test::Deep;
with qw(Test::Log::Dis::Patchy::RoleTester);

{
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
}

{
    # a stubbly little Log::Dis::Patchy::Output consumer, has an attribute,
    # an_arg, that it passes through to the LDO class that it is responsible
    # for building.
    package LDPO;
    use Moo;
    sub _build_ldo_name         {'test_output'}
    sub _build_ldo_package_name {'LDO'}
    with qw(Log::Dis::Patchy::Output);
    has an_arg => ( is => 'ro' );
    around _build_ldo_init_args => sub {
        my ( $orig, $self ) = ( shift, shift );
        my $args = $self->$orig(@_);
        $args = { %{$args}, an_arg => $self->an_arg, };
        return $args;
    };
}

# Build an LDPO instance and ask it to build an LDO instance.  See if it was
# passed the correct init_args.
test 'exercise a class that consumes role' => sub {
    my $self     = shift;
    my $ldpo_obj = LDPO->new( { an_arg => 'a_value' } );
    my $output   = $ldpo_obj->output;
    isa_ok($output, 'Log::Dispatch::Output', 'the output object');
    cmp_deeply(
        $output->{args_to_ldo_new},
        {   name      => 'test_output',
            max_level => 'emergency',
            min_level => 'debug',
            an_arg    => 'a_value',
        },
        '... and the correct info was passed to constructor'
    );

};

run_me(
    'test Log::Dis::Patchy::Output',
    {   role_name     => 'Log::Dis::Patchy::Output',
        expected_subs => [
            qw( ldo_max_level _build_ldo_max_level
                ldo_min_level _build_ldo_min_level
                ldo_name ldo_package_name
                ldo_init_args _build_ldo_init_args
                output _build_output)
        ],
        required_subs => [qw( _build_ldo_name _build_ldo_package_name )],
    }
);

done_testing;
