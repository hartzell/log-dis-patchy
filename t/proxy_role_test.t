#!perl

use Test::Roo;

use lib qw(t/lib);
with qw(Test::Log::Dis::Patchy::RoleTester);

use Test::Exception;

{

    package LDP;
    use Moo;
    sub _build_outputs { ['LDPO'] }
    with qw(Log::Dis::Patchy);
    sub _build__proxy_package {'LDPP'}
}

{

    package LDPP;
    use Moo;

    with qw(Log::Dis::Patchy::Proxy);
}

test 'build a proxy, is it cool?' => sub {
    my $self = shift;
    my $logger = LDP->new( { ident => 'tester' } );
    my $proxy
        = LDPP->new( { parent => $logger, proxy_prefix => 'prefix: ' } );

    isa_ok( $logger, 'LDP',  'The logger' );
    isa_ok( $proxy,  'LDPP', 'The proxy' );

    $proxy->log("test to proxy");
    cmp_deeply(
        $logger->messages,
        [ superhashof( { message => 'prefix: test to proxy' } ) ],
        'check proxy logging'
    );
    $logger->reset_messages;
    $logger->log("test to logger");
    cmp_deeply(
        $logger->messages,
        [ superhashof( { message => 'test to logger' } ) ],
        'check logger logging'
    );

    $logger->reset_messages;
    $proxy->prefix("another proxy prefix: ");
    $proxy->log('testing 321');
    cmp_deeply(
        $logger->messages,
        [   superhashof(
                { message => 'prefix: another proxy prefix: testing 321' }
            )
        ],
        'check proxy prefix'
    );

    $logger->reset_messages;
    $proxy->clear_prefix();
    $proxy->log('testing 321');
    cmp_deeply(
        $logger->messages,
        [ superhashof( { message => 'prefix: testing 321' } ) ],
        'check proxy clear_prefix'
    );

    # test mute and log_fatal interaction.
    $logger->reset_messages;
    $proxy->mute();
    $proxy->log('testing 321');
    dies_ok { $proxy->log_fatal("a testing fatality"); } 'log_fatal dies';
    cmp_deeply(
        $logger->messages,
        [ superhashof( { message => 'prefix: a testing fatality' } ) ],
        'check proxy log_fatal'
    );
    $proxy->unmute();

    $logger->reset_messages;
    my $pp = $proxy->proxy( { proxy_prefix => 'pp: ' } );
    $pp->log('a double proxy test');
    cmp_deeply(
        $logger->messages,
        [ superhashof( { message => 'prefix: pp: a double proxy test' } ) ],
        'check double proxy'
    );

};

test 'check that the various log levels are hooked up.' => sub {
    my $self = shift;
    my $logger = LDP->new( { ident => 'log_level_test' } );
    my $proxy
        = LDPP->new( { parent => $logger, proxy_prefix => 'prefix: ' } );

    $logger->debug(1);
    isa_ok( $logger, 'LDP', 'The logger' );
    isa_ok( $proxy,  'LDPP', 'The proxy' );

    $proxy->log("quick test of log method");
    cmp_deeply(
        $logger->messages,
        [   {   level   => 'info',
                message => 'prefix: quick test of log method',
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
        $proxy->$method("testing $level");
        cmp_deeply(
            $logger->messages,
            [   {   level   => $level,
                    message => "prefix: testing $level",
                    name    => 'test_output'
                }
            ],
            "test a simple log message at level: $level"
        );
        $logger->reset_messages;
    }
};

run_me(
    'test Log::Dis::Patchy::Proxy',
    {   role_name     => 'Log::Dis::Patchy::Proxy',
        expected_subs => [
            qw(
                prefix  clear_prefix proxy_prefix _get_all_prefixes

                debug set_local_debug get_local_debug  has_local_debug
                clear_debug

                muted set_local_muted get_local_muted has_local_muted clear_muted
                mute unmute

                messages reset_messages

                ident
                config_id

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

                proxy
                parent _assert_parent
                )
        ],

    }
);

done_testing;
