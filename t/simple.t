#!perl

use Test::More;

{

    package AnOutput;
    use Moo;

    use MooX::Types::MooseLike::Base qw(ArrayRef HashRef Str);

    sub _build_ldo_package_name {'Log::Dispatch::Array'}

    sub _build_ldo_defaults {
        {   name      => 'an_output',
            min_level => 'debug',
            array     => $_[0]->_messages,
        };
    }

    has _messages => (
        is      => 'ro',
        isa     => ArrayRef,
        default => sub { [] },
        clearer => 1,
    );

    with 'Log::Dis::Patchy::Output';
}

{

    package FileOutput;
    use Moo;
    use MooX::Types::MooseLike::Base qw(Str);
    use Log::Dis::Patchy::Helpers qw(add_newline_callback);

    sub _build_ldo_package_name {'Log::Dispatch::File'}

    sub _build_ldo_defaults {
        {   name      => 'file',
            min_level => 'debug',
            filename  => '/tmp/foo',
            callbacks => [ add_newline_callback, ],
        };
    }

    with 'Log::Dis::Patchy::Output';
}

{

    package MyStdLogger;
    use Moo;

    sub _build_outputs { [ 'AnOutput', ] }

    with qw(Log::Dis::Patchy);
}

use Log::Dis::Patchy::Helpers qw(log_pid_callback);

my $l = MyStdLogger->new(
    {   ident => 'foo',
        outputs =>
            [ 'AnOutput', 'FileOutput' => { filename => '/tmp/zowy' }, ],
        callbacks => [ log_pid_callback() ],
    }
);

$DB::single = 1;

isa_ok( $l->_dispatcher, "Log::Dispatch" );

$l->_dispatcher->log( level => 'debug', message => "shite!" );

done_testing;
