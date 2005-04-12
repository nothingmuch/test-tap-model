#!/usr/bin/perl

use Test::More 'no_plan';

use strict;
use warnings;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model") };

{
	my $s = strap_this(skip_some => <<TAP);
1..2
ok 1 foo # skip cause i said so
ok 2 bar
TAP

	is($s->test_files, 1, "one file");
	isa_ok(my $f = ($s->test_files)[0], "Test::TAP::Model::File");

	is(my @cases = $f->cases, 2, "two subtests");
	ok($cases[0]->ok, "1 ok");
	ok($cases[0]->skipped, "1 skip");
	is($cases[0]->reason, "cause i said so", "reason");
	ok($cases[1]->ok, "2 ok");
	ok(!$cases[1]->skipped, "2 not skip");
}

{
	my $s = strap_this(bail_out => <<TAP);
1..2
ok 1 foo
Bail out!
TAP

	is($s->test_files, 1, "one file");
	isa_ok(my $f = ($s->test_files)[0], "Test::TAP::Model::File");

	is(my @cases = $f->subtests, 1, "one subtest");
}

{
	my $s = strap_this(todo_tests => <<TAP);
1..4
ok 1 foo
not ok 2 bar
not ok 3 gorch # TODO burp
ok 4 baz # TODO bzzt
TAP

	is($s->test_files, 1, "one file");
	isa_ok(my $f = ($s->test_files)[0], "Test::TAP::Model::File");
	
	is($f->cases, 4, "three cases");
	is($f->planned, 4, "three planned");

	my @cases = $f->cases;

	isa_ok($cases[0], "Test::TAP::Model::Subtest");
	ok($cases[0]->ok, "1 ok");
	ok(!$cases[0]->todo, "not todo");
	ok($cases[0]->actual_ok, "actual ok");
	ok($cases[0]->normal, "normal");
	ok(!$cases[1]->ok, "2 nok -> nok");
	ok(!$cases[1]->todo, "not todo");
	ok(!$cases[1]->actual_ok, "actual nok");
	ok(!$cases[1]->normal, "not normal");
	ok($cases[2]->ok, "3 nok todo -> ok") or diag "line: '" . $cases[2]->line . "'";
	ok($cases[2]->todo, "todo");
	ok(!$cases[2]->actual_ok, "actual nok");
	ok($cases[2]->normal, "normal");
	ok($cases[3]->ok, "4 ok todo -> ok");
	ok($cases[3]->todo, "todo");
	ok($cases[3]->actual_ok, "actual ok");
	ok(!$cases[3]->normal, "not normal");
}

{
	my $s = strap_this(skip_all => <<TAP);
1..0 # skipped: dancing beavers
TAP

	my @files = $s->test_files;
	is(@files, 1, "one file");

	isa_ok(my $f = $files[0], "Test::TAP::Model::File");

	ok($f->skipped, "whole file was skipped");
	is($f->cases, 0, "no test cases");
}


sub strap_this {
	my $name = shift;
	my $output = shift;
	$output = [split /\n/,$output];

	my $s = $m->new;
	my $r = $s->start_file($name);
	eval { $r->{results} = { $s->analyze($name, $output) } };

	return $s;
}
