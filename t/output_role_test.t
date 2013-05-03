#!perl

use Test::Roo;

use lib qw(t/lib);
with qw(Test::Log::Dis::Patchy::RoleTester);

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
        required_subs => [ qw( _build_ldo_name _build_ldo_package_name ) ],
    }
);

done_testing;
