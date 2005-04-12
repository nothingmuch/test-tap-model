#!/usr/bin/perl

use strict;
use warnings;

# TODO not very comprehensive

use Test::More tests => 14;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model::File") }

isa_ok(my $f = $m->new(my $file = {
	events => [
		my $ok_case = {
			type => "test",
			ok => 1,
		},
		my $nok_case = {
			type => "test",
			ok => 0,
		},
	],
	results => my $r = {
		passed => 0,
		max => 3,
		seen => 2,
	}
}), $m);

ok(!$f->ok, "failed");
$r->{passed} = 1;
ok($f->ok, "passed");
is($f->passed, $f->ok, "alias");
is($f->failed, !$f->ok, "negation");

ok(!$f->skipped, "not all skipped");
$r->{skip_all} = "reason";
ok($f->skipped, "all skipped");

is($f->max, 3, "3 planned");
is($f->seen, 2, "but two seen");
is($f->passed_tests, 1, "one of these passed");
is($f->failed_tests, 1, "one failed");
is($f->todo_tests, 0, "none are todo");
$nok_case->{todo} = 1;
is($f->todo_tests, 1, "one is todo");

