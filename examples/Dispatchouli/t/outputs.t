
use Test::Roo;

use lib qw(../../lib);
use lib qw(t/lib);

with qw(OutputTester);

# don't test to_self, rjbs wrote it from scratch, I used L::D::Array

run_me(
    'test to_stdout',
    {   output_name      => 'stdout',
        init_args        => { ident => 'test_me', to_stdout => 1 },
        interesting_keys => [qw(name max_level min_level stderr)],
    }
);
run_me(
    'test to_stderr',
    {   output_name      => 'stderr',
        init_args        => { ident => 'test_me', to_stderr => 1 },
        interesting_keys => [qw(name max_level min_level stderr)],
    }
);

run_me(
    'test syslog',
    {   output_name => 'syslog',
        init_args   => { ident => 'test_me', facility => 'daemon' },
        interesting_keys =>
            [qw(name max_level min_level socket logopt facility)],
    }
);

# filename check *slightly* dodgy, includes YYYYMMDD
# don't test at midnight...
run_me(
    'test to_file',
    {   output_name      => 'logfile',
        init_args        => { ident => 'test_me', to_file => 1 },
        interesting_keys => [
            qw(name max_level min_level filename
                mode permissions syswrite close autoflush binmode)
        ],
    }
);

run_me(
    'test to_file with log_file',
    {   output_name => 'logfile',
        init_args => { ident => 'test_me', to_file => 1, log_file => 'doh' },
        interesting_keys => [
            qw(name max_level min_level filename
                mode permissions syswrite close autoflush binmode)
        ],
    }
);

run_me(
    'test to_file with log_{file,path}',
    {   output_name => 'logfile',
        init_args   => {
            ident    => 'test_me',
            to_file  => 1,
            log_file => 'doh',
            log_path => '/tmp'
        },
        interesting_keys => [
            qw(name max_level min_level filename
                mode permissions syswrite close autoflush binmode)
        ],
    }
);

{ local $ENV{DISPATCHOULI_PATH} = "/tmp/";
  run_me(
      'test to_file with $ENV{DISPATCHOULI_PATH} = "/tmp/"',
      {   output_name => 'logfile',
          init_args   => {
              ident    => 'test_me',
              to_file  => 1,
          },
          interesting_keys => [
              qw(name max_level min_level filename
                 mode permissions syswrite close autoflush binmode)
          ],
      }
  );
}

done_testing;
