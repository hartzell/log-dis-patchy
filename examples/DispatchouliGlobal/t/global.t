#!perl

use lib 't/lib';
use Test::More;

use LDPGlobal '$Logger' => {
    init => {
        ident => 'global_test',
    },
};

isa_ok($Logger, 'LDP', 'Global logger is correct class');
is($Logger->ident, 'global_test', 'ident is correct');

done_testing;
