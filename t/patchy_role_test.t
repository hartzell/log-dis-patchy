#!perl

use Test::Roo;

use lib qw(t/lib);
with qw(Test::Log::Dis::Patchy::RoleTester);

run_me(
    'test Log::Dis::Patchy',
    {   role_name     => 'Log::Dis::Patchy',
        expected_subs => [
            qw(
                _dispatcher _build__dispatcher
                _patchy_outputs _build__patchy_outputs
                 callbacks _build_callbacks
                config_id _build_config_id
                flogger _build_flogger
                quiet_fatal _build_quiet_fatal

                debug
                failure_is_fatal
                ident
                muted mute unmute
                outputs
                prefix clear_prefix

                log
                log_debug
                log_fatal

                messages reset_messages

                proxy
                _proxy_package _build__proxy_package
               )
        ],
        required_subs => [qw( _build_outputs )],
    }
);

done_testing;
