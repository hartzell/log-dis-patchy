
use strict;
use warnings;

package Log::Dis::Patchy::Helpers;

# ABSTRACT: Helpful things for Log::Dis::Patchy users.

=head1 SYNOPSIS

    use Log::Dis::Patchy::Helpers qw(prepend_pid_callback);

    ...;
    sub _build_callbacks { [ prepend_pid_callback ] }

=head1 DESCRIPTION

Provides useful subroutines that generate subroutines that can be used as
L<Log::Dispatch> style callbacks.

Exported using L<Sub::Exporter>, renaming supported, etc...

=cut

use Sub::Exporter -setup => {
    exports => [
        qw( append_newline_callback
            prepend_pid_callback
            prepend_timestamp_callback )
    ],
};

=func prepend_pid_callback

Returns a L<Log::Dispatch> style callback function that prepends "[PID] " to
the log message (where PID is the process id).

=cut

sub prepend_pid_callback {
    return sub {
        my %i = @_;

        return "[$$] " . $i{message};
    };
}

=func append_newline_callback

Returns a L<Log::Dispatch> style callback function that appends a newline to
the log message.

=cut

sub append_newline_callback {
    return sub {
        my %i = @_;
        return $i{message} . "\n";
    };
}

=func prepend_timestamp_callback

Returns a L<Log::Dispatch> style callback function that prepends a timestamp to
the log message (e.g. "Sat May  4 10:16:25 2013").

=cut

sub prepend_timestamp_callback {
    return sub {
        my %i = @_;
        return (localtime) . ' ' . $i{message};
    };
}

=head1 SEE ALSO
=for :list
* L<Sub::Exporter>

=cut

1;

