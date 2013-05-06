
package Log::Dis::Patchy::Ouli::Self;

use namespace::autoclean;
use Moo;

use MooX::Types::MooseLike::Base qw(ArrayRef);

sub _build_ldo_name         {'self'}
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

1;
