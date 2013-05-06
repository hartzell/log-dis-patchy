
package Log::Dis::Patchy::Ouli::Syslog;

use namespace::autoclean;
use Moo;

sub _build_ldo_name         {'syslog'}
sub _build_ldo_package_name {'Log::Dispatch::Syslog'}

with 'Log::Dis::Patchy::Output';

around _build_ldo_init_args => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $args = $self->$orig(@_);

    $args->{facility}  = $self->_patchy->facility;
    $args->{logopt}    = 'pid';
    $args->{socket}    = 'native';
    $args->{callbacks} = [
        sub {
            my %arg     = @_;
            my $message = $arg{message};
            $message =~ s/\n/<LF>/g;
            return $message;
        },
    ];

    return $args;
};

1;
