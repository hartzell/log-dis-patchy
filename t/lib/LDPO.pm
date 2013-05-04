# a stubbly little Log::Dis::Patchy::Output consumer, has an attribute,
# an_arg, that it passes through to the LDO class that it is responsible
# for building.
package LDPO;
use Moo;
sub _build_ldo_name         {'test_output'}
sub _build_ldo_package_name {'LDO'}
with qw(Log::Dis::Patchy::Output);
has an_arg => ( is => 'ro' );
around _build_ldo_init_args => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $args = $self->$orig(@_);
    $args = { %{$args}, an_arg => $self->an_arg, };
    return $args;
};

1;
