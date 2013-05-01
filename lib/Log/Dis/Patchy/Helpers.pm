
package Log::Dis::Patchy::Helpers;

use Sub::Exporter -setup => { exports => [qw(add_newline_callback
                                             log_pid_callback)], };

sub log_pid_callback {
    return sub {
        my %i = @_;

        return "[$$] " . $i{message};
    };
}

sub add_newline_callback {
    return sub {
        my %i = @_;
        return $i{message} . "\n";
    };
}

1;
