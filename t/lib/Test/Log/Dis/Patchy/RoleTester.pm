package Test::Log::Dis::Patchy::RoleTester;

# ABSTRACT: Test::Roo role for basic role behaviour.

=head1 SYNOPSIS

    use Test::Roo;

    use lib qw(t/lib);
    with qw(Test::App::Rosie::RoleTester);

    run_me(
        'test Some::Role',
        {   role_name     => 'Some::Role',
            required_subs => [qw(name run)],
        }
    );

    run_me(
        'test Some::Other::Role,
        {   role_name     => 'Some::Other::Role',
            required_subs => [qw(test)],
            expected_subs => [qw(frob twiddle dorp)],
        }
    );

    done_testing;

=head1 DESCRIPTION

This is a role for L<Test::Roo> based tests.  It is checks that a role can be
composed into a package that provides the required set of subs, that the
package then "does" the role and that the package's namespace is not
unexpectedly polluted.

=cut

use Test::Roo::Role;

use Test::Exception;
use Test::Deep;

use MooX::Types::MooseLike::Base qw(ArrayRef Str);
use Package::Generator;
use Package::Reaper;

=attr expected_subs

A reference to an array that contains the names of the subs that the role
provides to a consuming class.  Names should not include a package prefix.

It is used check that the role did not pollute the consuming package's
namespace any more than expected.

This needs to be a complete list, including both Moo{,se}-ish stuff (getters,
setters, builders, etc....), explicitly declared subs and anything that was
imported and not cleaned up (e.g. importing C<any> from C<List::MoreUtils>).

=attr required_subs

A reference to an array that contains the names of the subs that the role
requires of a consuming class.  Names should not include a package prefix.

=cut

has [qw/expected_subs required_subs/] => (
    is      => 'rw',
    isa     => ArrayRef [Str],
    default => sub { [] },
    lazy    => 1,
);

=attr role_name

The full package name of the role, e.g. C<Test::Roo::Role>.

=cut

has role_name => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

=func _build_package

A private method that builds a package and an associated reaper (see
L<Package::Generator> and L<Package::Reaper>) into which the test will compose
the role under scrutiny.

=cut

sub _build_package {
    my @sub_names = @_;

    # build a stubby sub for each name in the list.
    my @args = map {
        $_ => sub {"$_"}
    } @sub_names;

    my $p = Package::Generator->new_package( { data => \@args } );
    my $r = Package::Reaper->new($p);

    return ( $p, $r );
}

=head1 TESTS

=head2 compose role into a package that meets the requirements

Applies the role to a package which should meet all of the roles requirements.

Checks that:

=over 4

=item - the role can be applied to the package

=item -the package "does" the role

=item - the package has gained the expected set of subs

=item - the package has NOT gained any unexpected subs

=back

=head2 compose role into a package missing one of the requirements

For each sub in the list of subs required by the role, this test builds a
package that is missing that sub and checks that:

Checks that:

=over 4

=item - the role can NOT be applied to the package

=item - the exception contains the expected message.

=back

=cut

test 'compose role into a package that meets the requirements' => sub {
    my $self = shift;

    # build a package with stubbed subs to satis. requires
    my ( $p, $r ) = _build_package( @{ $self->required_subs } );

    # make sure that the role can be consumed.
    lives_ok {
        Moo::Role->apply_roles_to_package( $p, $self->role_name );
    }
    'can apply role the to the package';

    # make sure that class does the role.
    is( $p->does( $self->role_name ), 1, 'the package "does" the role' );

    # make sure that role installed what it was supposed to.
SKIP: {
        skip( "there are no expected subs", 1 )
            unless @{ $self->expected_subs };
        can_ok( $p, @{ $self->expected_subs } );
    }

    # make sure that the role didn't install anything unexpected.
    # think about Class::Sniff or Class::Inspector...
    {
        no strict 'refs';

        # get a list of the subs in the package
        # (look into Class::Sniff and Class::Inspector?)
        my @subs_in_package = grep { defined &{"$p\::$_"} } keys %{"$p\::"};

        # make sure there are no extras (except DOES and does).
        cmp_deeply(
            [ grep { $_ !~ qr/does/i } @subs_in_package ],
            bag( @{ $self->required_subs }, @{ $self->expected_subs } ),
            'make sure nothing unexpected was imported'
        );
    }
};

test 'compose role into a package missing one of the requirements' => sub {
    my $self = shift;

    plan skip_all =>
        'skip check for missing requirements, none were specified'
        unless @{ $self->required_subs };

    foreach my $s ( @{ $self->required_subs } ) {

        my @other_subs = grep { $_ ne $s } @{ $self->required_subs };
        my $role_name = $self->role_name;

        my ( $p, $r ) = _build_package(@other_subs);

        throws_ok {
            Moo::Role->apply_roles_to_package( $p, $self->role_name );
        }
        qr{Can't\sapply\s
                   $role_name\s
                   .*
                   missing\s
                   $s\s
                   .*
          }x, "composing roll into package missing '$s' should not work";

    }
};

=head1 SEE ALSO

L<Package::Generator>, L<Package::Reaper>, L<Test::Roo>, L<Moo::Role>,
L<Role::Tiny>

=cut

1;
