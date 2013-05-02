#!perl

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
    use Log::Dis::Patchy::Helpers qw(add_newline_callback);
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
    sub _build_callbacks { [add_newline_callback] }

    around _build_ldo_init_args => sub {
        my ( $orig, $self ) = ( shift, shift );
        my $args = {
            %{ $self->$orig(@_) },
            filename  => path( $self->log_path, $self->log_file ) . "",
            callbacks => $self->callbacks,
        };
        return $args;
    };

}

{

    package MyStdLogger;
    use Moo;

    use Log::Dis::Patchy::Helpers qw(log_pid_callback);

    sub _build_outputs { [ 'AnOutput', 'FileOutput' ] }

    sub _build_callbacks { [ log_pid_callback() ] }

    with qw(Log::Dis::Patchy);
}

my $l = MyStdLogger->new( { ident => 'foo', } );

$DB::single = 1;

isa_ok( $l->_dispatcher, "Log::Dispatch" );

$l->log("shite!");
$l->log_debug("debugging shite!");

print "foo";
done_testing;
