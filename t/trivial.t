#!perl

use strict;
use warnings;
use Capture::Tiny qw(capture);
use Test::More;
use Test::Deep;

{

    package TrivialOutput;
    use Moo;

    use Log::Dis::Patchy::Helpers qw(append_newline_callback);

    sub _build_ldo_name         {'an_output'}
    sub _build_ldo_package_name {'Log::Dispatch::Screen'}

    with 'Log::Dis::Patchy::Output';

    around _build_ldo_init_args => sub {
        my ( $orig, $self ) = ( shift, shift );
        my $args = $self->$orig(@_);

        $args->{callbacks} = [ append_newline_callback() ];
        return $args;
    };
}

{

    package TrivialLogger;
    use Moo;

    use Log::Dis::Patchy::Helpers qw(prepend_pid_callback);

    sub _build_outputs   { ['TrivialOutput'] }
    sub _build_callbacks { [prepend_pid_callback] }

    with qw(Log::Dis::Patchy);
}

my $l = TrivialLogger->new( { ident => 'trivial', } );

isa_ok( $l->_dispatcher, "Log::Dispatch" );

my ( $stdout, $stderr, @result ) = capture {
    $l->mute();
    $l->log("a message");
    $l->unmute();
    $l->log("another message");
    $l->log_debug("debugging message");
    $l->debug(1);
    $l->log_debug("another debugging message");
};

is($stdout, '', 'stdout is empty');
like($stderr, qr/^\[\d+\]\sanother\smessage\n
                  \[\d+\]\sanother\sdebugging\smessage$/x, 'stderr is ok');

done_testing;
