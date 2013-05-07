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

                log log_debug log_fatal

                parent _assert_parent
                )
        ],

    }
);

done_testing;
