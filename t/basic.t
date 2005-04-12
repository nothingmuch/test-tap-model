#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;

my $m;

BEGIN { use_ok($m = "Test::TAP::Model") }

isa_ok(my $t = $m->new, $m);
isa_ok($t, "Test::Harness::Straps");

can_ok($t, "start_file");
my $e = $t->start_file("example");

$e->{results} = { $t->analyze_fh("example", \*DATA) };

isa_ok(my $s = $t->structure, "HASH");

is_deeply([ sort keys %$s ], [ "test_files" ], "keys of structure");

is(@{ $s->{test_files} }, 1, "one test file");

my $f = $s->{test_files}[0];
is_deeply([ sort keys %$f ], [ sort qw/file results events/ ], "keys of file hash");
is(my @e = @{$f->{events}}, 3, "three events");


# this compares the hash structures to the ones we expect to get
# from Test::Harness::Straps events
is($e[0]->{type}, "test", "first event is a test");
ok($e[0]->{ok}, "it passed");
ok(!$e[0]->{diag}, "no diagnosis");

is($e[1]{type}, "test", "second event is a test");
ok(!$e[1]->{ok}, "it failed");

is($e[2]{type}, "test", "third event is a test");
ok($e[2]{todo}, "it's a todo test");


# this is the return from analyze_foo
ok(exists($f->{results}), "file wide results also exist");
is($f->{results}{seen}, 3, "total of three tests");
is($f->{results}{ok}, 2, "two tests ok");
ok(!$f->{results}{passed}, "file did not pass");


__DATA__
1..3
ok 1 - foo
not ok 2 - bar
#     Failed test (t/example.t at line 9)
#          got: '1'
#     expected: '2'
not ok 3 - gorch # TODO not yet
#     Failed (TODO) test (t/example.t at line 12)
#          got: '2'
#     expected: '4'
# Looks like you failed 1 test of 3.

