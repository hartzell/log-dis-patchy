#!perl

use Test::Roo;

use lib qw(t/lib);
with qw(Test::Log::Dis::Patchy::RoleTester);

{

    package LDP;
    use Moo;
    sub _build_outputs { ['LDPO'] }
    with qw(Log::Dis::Patchy);
}

test 'build a logger, is it cool?' => sub {
    my $self = shift;
    my $logger = LDP->new( { ident => 'test_me' } );

    isa_ok( $logger, 'LDP', 'The logger' );
    $logger->log("something");
    cmp_deeply(
        $logger->messages,
        [   {   level   => 'info',
                message => 'something',
                name    => 'test_output'
            }
        ],
        'test a simple log message'
    );

    $logger->reset_messages;
    $logger->debug(1);
    $logger->log_debug("something debuggy");
    cmp_deeply(
        $logger->messages,
        [   {   level   => 'debug',
                message => 'something debuggy',
                name    => 'test_output'
            }
        ],
        'test a debug message with debug(1)'
    );

    $logger->reset_messages;
    $logger->debug(0);
    $logger->log_debug("something debuggy");
    cmp_deeply( $logger->messages, [], 'test a debug message with debug(0)' );

    $logger->prefix("PRE-FIX: ");
    $logger->log("something");
    cmp_deeply(
        $logger->messages,
        [   {   level   => 'info',
                message => 'PRE-FIX: something',
                name    => 'test_output'
            }
        ],
        'test a simple log message with a prefix'
    );

    $logger->reset_messages;
    $logger->mute();
    $logger->log("something muted");
    cmp_deeply( $logger->messages, [], 'test a message after mute.' );

    $logger->reset_messages;
    $logger->unmute();
    $logger->log("something unmuted");
    cmp_deeply(
        $logger->messages,
        [   {   level   => 'info',
                message => 'PRE-FIX: something unmuted',
                name    => 'test_output'
            }
        ],
        'test a message after unmute'
    );

};

test 'check that the various log levels are hooked up.' => sub {
    my $self = shift;
    my $logger = LDP->new( { ident => 'log_level_test' } );

    $logger->debug(1);
    isa_ok( $logger, 'LDP', 'The logger' );
    $logger->log("quick test of log method");
    cmp_deeply(
        $logger->messages,
        [   {   level   => 'info',
                message => 'quick test of log method',
                name    => 'test_output'
            }
        ],
        'test a simple log message'
    );
    $logger->reset_messages;

    for my $level (
        qw(debug info notice warning error critical alert emergency))
    {
        my $method = "log_$level";
        $logger->$method("testing $level");
        cmp_deeply(
            $logger->messages,
            [   {   level   => $level,
                    message => "testing $level",
                    name    => 'test_output'
                }
            ],
            "test a simple log message at level: $level"
        );
        $logger->reset_messages;
    }
};

run_me(
    'test Log::Dis::Patchy',
    {   role_name     => 'Log::Dis::Patchy',
        expected_subs => [
            qw(
                _dispatcher _build__dispatcher _clear_dispatcher
                _patchy_outputs _build__patchy_outputs
                callbacks _build_callbacks
                config_id _build_config_id
                flogger _build_flogger

                debug _build_debug
                failure_is_fatal _build_failure_is_fatal
                ident
                muted mute unmute
                outputs
                prefix clear_prefix

                log
                log_fatal

                log_debug
                log_info
                log_notice
                log_warning
                log_error
                log_critical
                log_alert
                log_emergency

                messages reset_messages

                proxy
                _proxy_package _build__proxy_package
                )
        ],
        required_subs => [qw( _build_outputs )],
    }
);

done_testing;
