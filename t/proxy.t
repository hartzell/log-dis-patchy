#!perl

use strict;
use warnings;
use Test::More;

{

    package AnOutput;
    use Moo;

    use MooX::Types::MooseLike::Base qw(ArrayRef);

    sub _build_ldo_name         {'an_output'}
    sub _build_ldo_package_name {'Log::Dispatch::Array'}

    with 'Log::Dis::Patchy::Output';

    has messages => (
        is      => 'ro',
        isa     => ArrayRef,
        default => sub { [] },
    );

    sub reset_messages { @{ $_[0]->messages } = () }

    around _build_ldo_init_args => sub {
        my ( $orig, $self ) = ( shift, shift );
        my $args = $self->$orig(@_);
        $args = { %{$args}, array => $self->messages, };
        return $args;
    };
}

{

    package FileOutput;
    use Moo;

    use File::Spec;
    use Log::Dis::Patchy::Helpers qw(add_newline_callback
        timestamp_prefix_callback
    );
    use MooX::Types::MooseLike::Base qw(ArrayRef CodeRef InstanceOf Str);
    use Path::Tiny;

    sub _build_ldo_name         {'file_output'}
    sub _build_ldo_package_name {'Log::Dispatch::File'}

    with 'Log::Dis::Patchy::Output';

    has log_path => ( is => 'lazy', isa => Str, );
    sub _build_log_path { File::Spec->tmpdir; }

    has log_file => ( is => 'lazy', isa => Str, );

    sub _build_log_file {
        sprintf( '%s.%04u%02u%02u',
            $_[0]->ldo_name,
            ( (localtime)[5] + 1900 ),
            sprintf( '%02d', (localtime)[4] + 1 ),
            sprintf( '%02d', (localtime)[3] ),
        );
    }

    has _filename => (
        is       => 'lazy',
        init_arg => undef,
        isa      => InstanceOf ['Path::Tiny'],
    );

    sub _build__filename {
        return path( $_[0]->log_path, $_[0]->log_file );
    }

    has callbacks => ( is => 'lazy', isa => ArrayRef [CodeRef], );

    sub _build_callbacks {
        [ timestamp_prefix_callback, add_newline_callback ];
    }

    around _build_ldo_init_args => sub {
        my ( $orig, $self ) = ( shift, shift );
        my $args = {
            %{ $self->$orig(@_) },
            filename  => path( $self->log_path, $self->log_file ) . "",
            callbacks => $self->callbacks,
            mode      => 'append',
        };
        return $args;
    };

}

{

    package MyStdLogger;
    use Moo;

    use Log::Dis::Patchy::Helpers qw(log_pid_callback);

    sub _build_outputs {
        [   'AnOutput',
            'FileOutput' => {
                log_path => '/tmp',
                log_file => 'fu-dog',
            }
        ];
    }

    sub _build_callbacks { [ log_pid_callback() ] }

    with qw(Log::Dis::Patchy);
}

my $l = MyStdLogger->new( { ident => 'foo', } );

$DB::single = 1;

isa_ok( $l->_dispatcher, "Log::Dispatch" );

use Log::Dis::Patchy::Proxy;
my $p = Log::Dis::Patchy::Proxy->new(
    parent       => $l,
    proxy_prefix => 'PROXY: ',
);

$p->mute();
$p->log("shite!");
$p->unmute();
$p->log("bollocks!");
$p->log_debug("debugging shite!");
$p->prefix(" -zoinks- ");
$p->debug(1);
$p->log_debug("debugging bollocks");
$p->clear_prefix;
$p->log_debug("debugging bollocks without zoinks");

done_testing;
