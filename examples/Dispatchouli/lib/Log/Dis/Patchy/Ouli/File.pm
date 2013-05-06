
package Log::Dis::Patchy::Ouli::File;

use namespace::autoclean;
use Moo;

use Log::Dis::Patchy::Helpers qw(prepend_timestamp_callback);
use MooX::Types::MooseLike::Base qw(Str);

sub _build_ldo_name         {'logfile'}
sub _build_ldo_package_name {'Log::Dispatch::File'}

with 'Log::Dis::Patchy::Output';

has log_file => ( is => 'lazy', isa => Str );

sub _build_log_file {
    my $self = shift;

    my $path
        = $self->_patchy->log_path
        || $self->_patchy->env_value('PATH')
        || File::Spec->tmpdir;
    my $filename = $self->_patchy->log_file
        || sprintf( '%s.%04u%02u%02u',
        $self->_patchy->ident,
        ( (localtime)[5] + 1900 ),
        sprintf( '%02d', (localtime)[4] + 1 ),
        sprintf( '%02d', (localtime)[3] ),
        );

    my $log_file = File::Spec->catfile( $path, $filename );
    return $log_file;
}

around _build_ldo_init_args => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $args = $self->$orig(@_);

    $args->{mode}      = 'append';
    $args->{filename}  = $self->log_file;
    $args->{callbacks} = [ prepend_timestamp_callback() ];

    return $args;
};

1;
