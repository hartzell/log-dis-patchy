use strict;
use warnings;

package LDPGlobal;

use parent qw(Log::Dispatchouli::Global);
use LDP;

sub logger_globref {
    no warnings 'once';
    return \*Logger;
}

sub default_logger_class { 'LDP' }
sub default_logger_args { { ident => 'default' } }

my $default_logger;
sub default_logger_ref { return \$default_logger}

1;
