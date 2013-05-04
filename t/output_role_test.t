#!perl

use Test::Roo;

use lib qw(t/lib);
use Test::Deep;
with qw(Test::Log::Dis::Patchy::RoleTester);

use LDPO;

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
