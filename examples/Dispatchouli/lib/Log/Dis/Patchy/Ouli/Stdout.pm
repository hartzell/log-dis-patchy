
package Log::Dis::Patchy::Ouli::Stdout;

use namespace::autoclean;
use Moo;

use Log::Dis::Patchy::Helpers qw(append_newline_callback);

sub _build_ldo_name         {'stdout'}
sub _build_ldo_package_name {'Log::Dispatch::Screen'}

with 'Log::Dis::Patchy::Output';

around _build_ldo_init_args => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $args = $self->$orig(@_);

    $args->{callbacks} = [ append_newline_callback() ];
    $args->{max_level} = 'info'
        if ( grep( /stdout/, @{ $self->_patchy->quiet_fatal } ) );
    $args->{stderr} = 0;

    return $args;
};

1;
