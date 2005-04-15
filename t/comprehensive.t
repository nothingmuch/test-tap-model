#!/usr/bin/perl

use Test::More tests => 81;

use strict;
use warnings;

use List::Util qw/sum/;

my $m;
BEGIN { use_ok($m = "Test::TAP::Model") };

sub c_is (&$$){ # like Test::More::is, but in two contexts
	my $code = shift;
	my $exp = shift;
	my $desc = shift;

	my @list = &$code;
	my $scalar = &$code;

	is(@list, $exp, $desc . " in list context");
	is($scalar, $exp, $desc . " in scalar context");
}

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

	is(my @cases = $f->subtests, 2, "missing subtests after bailout are stubbed");

	ok(!$s->ok, "whole run is not ok");
	ok(!$f->ok, "file is not ok");
	ok($cases[0]->ok, "first case is ok");
	ok(!$cases[1]->ok, "but not second");
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
	
	is($f->cases, 4, "actual cases");
	is($f->planned, 4, "number planned");
	ok($f->nok, "file as a whole is not ok");

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

{
	my $s = strap_this(totals_1 => <<TAP1, totals_2 => <<TAP2);
1..2
ok 1 foo
not ok 2 bar
TAP1
1..4
ok 1 gorch
ok 2 baz # TODO fudge
not ok 3 poot # TODO zap
ok 4 bah # skip blah
TAP2

	is($s->test_files, 2, "two test files");
	ok(!$s->ok, "suite as a whole is not ok");

	my @files = $s->test_files;
	ok(!$files[0]->ok, "first file not ok");
	ok($files[1]->ok, "second file ok");

	is($files[0]->ratio, 1/2, "first file ratio");
	is($files[1]->ratio, 1/1, "second file ratio");

	is($s->total_ratio, 5/6, "total ratio");
	is($s->ratio, $s->total_ratio, "ratio alias also works");
	like($s->total_percentage, qr/^\d+(?:\.\d+)?%$/, "percentage is well formatted");

	my %expected = (
		seen	=> [ 2, 4],
		ok		=> [ 1, 4 ],
		nok		=> [ 1, 0 ],
		todo	=> [ 0, 2 ],
		skipped	=> [ 0, 1 ],
		unexpectedly_succeeded => [ 0, 1 ],
	);

	foreach my $method (keys %expected){
		my $fmeth = "${method}_tests";
		for my $i (0, 1){
			c_is(sub { $files[$i]->$fmeth }, $expected{$method}[$i], "file $i $method");
		}

		my $smeth = "total_$method";
		is($s->$smeth, sum(@{ $expected{$method} }), "total $method");
	}
}



sub strap_this {
	my $s = $m->new;

	while (@_){
		my $name = shift;
		my $output = shift;
		$output = [split /\n/,$output];

		my $r = $s->start_file($name);
		eval { $r->{results} = { $s->analyze($name, $output) } };
	}

	return $s;
}
