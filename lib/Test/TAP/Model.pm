#!/usr/bin/perl

package Test::TAP::Model;
use base qw/Test::Harness::Straps/;

use strict;
use warnings;

# callback handlers
sub _handle_bailout {
	my($self, $line, $type, $totals) = @_;

	$self->log_event(
		type => 'bailout',
		($self->{bailout_reason} ?
		 (reason => $self->{bailout_reason}) : ()),
	);

	die "Bailed out"; # catch with an eval { }
}
        
sub _handle_test {
	my($self, $line, $type, $totals) = @_;
	 my $curr = $totals->{seen}||0;

	# this is used by pugs' Test.pm, it's rather useful
	my $pos;
	if ($line =~ /^(.*?) <pos:(.*)>($|\s*#.*$)/){
		$line = $1 . $3;
		$pos = $2;
	}

	$self->log_event(
		type   => 'test',
		num    => $curr,
		ok     => $totals->{details}[-1]{ok},
		result => $totals->{details}[-1]{ok} # string for people
					? "ok $curr/$totals->{max}"
					: "NOK $curr",
		todo   => ($line =~ /# TODO/ ? 1 : 0),

		# pugs aux stuff
		line   => $line,
		pos    => $pos,
	);

	if( $curr > $self->{'next'} ) {
		$self->latest_event->{note} =
			"Test output counter mismatch [test $curr]\n";
	}
	elsif( $curr < $self->{'next'} ) {
		$self->latest_event->{note} = join("",
			"Confused test output: test $curr answered after ",
					  "test ", ($self->{'next'}||0) - 1, "\n");
	}
}

sub _handle_other {
	my($self, $line, $type, $totals) = @_;

	if (@{ $self->{meat}{test_files} } > 0) {
		$self->latest_event->{diag} .= $line;
	} else {
		($self->{meat}{test_files}[-1]{pre_diag} ||= "") .= $line;
	}
}

sub new_with_tests {
	my $pkg = shift;
	my @tests = @_;

	my $self = $pkg->SUPER::new;
	$self->run_tests(@tests);

	$self;
}

sub new_with_struct {
	my $pkg = shift;
	my $meat = shift;

	my $self = $pkg->SUPER::new(@_);
	$self->{meat} = $meat; # FIXME - the whole Test::Harness::Straps model can be figured out from this

	$self;
}

sub structure {
	my $self = shift;
	$self->{meat};
}

# just a dispatcher for the above event handlers
sub _init {
	my $s = shift;

	$s->{callback} = sub {
		my($self, $line, $type, $totals) = @_;

		my $meth = "_handle_$type";
		$self->$meth($line, $type, $totals) if $self->can($meth);
	};
}

sub log_event {
	my $self = shift;
	my %event = @_;

	push @{ $self->{events} }, \%event;
}

sub latest_event {
	my($self) = @_;
	$self->{events}[-1] || $self->log_event;
}

sub run {
	my $self = shift;
	$self->run_tests($self->get_tests);
}

sub get_tests {
	die 'the method get_tests is a stub. You must implement it yourself if you want $self->run to work.';
}

sub run_tests {
	my $self = shift;

	$self->_init;

	$self->{meat}{start_time} = time;

	foreach my $file (@_) {
		$self->run_test($file);
	}

	$self->{meat}{end_time} = time;
}

sub run_test {
	my $self = shift;
	my $file = shift;

	my $test_file = $self->start_file($file);
	
	my %results = $self->analyze_file($file);
	$test_file->{results} = \%results;

	$test_file;
}

sub start_file {
	my $self = shift;
	my $file = shift;

	push @{ $self->{meat}{test_files} }, my $test_file = {
		file => $file,
		events => ($self->{events} = []),
	};

	$test_file;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::Model - Accessible (queryable, serializable object) result collector
for L<Test::Harness::Straps> runs.

=head1 SYNOPSIS

	use Test::TAP::Model

	my $t = Test::TAP::Model->new($structure);

	my @tests = $t->test_files; # objects interface

	YAML::Dump($t->structure); # the same thing we made it with

	$t->run_tests(qw{ t/foo.t t/bar.t }); # has a side effect of creating struct

=head1 DESCRIPTION

This module is a subclass of L<Test::Harness::Straps> (although in an ideal
world it would really use delegation).

It uses callbacks in the straps object to construct a deep structure, with all
the data known about a test run accessible within.

It's purpose is to ease the processing of test data, for the purpose of
generating reports, or something like that.

The niche it fills is creating a way to access test run data, both from a
serialized and a real source, and to ease the querying of this data.

=head1 TWO INTERFACES

There are two ways to access the data in L<Test::TAP::Model>. The complex one,
which creates objects, revolves around the simpler one, which for Q&D purposes
is exposed and encouraged too.

Inside the object there is a well defined deep structure, accessed as

	$t->structure;

This is the simple method. It is a hash, containing some fields, and basically
organizes the test results, with all the fun fun data exposed.

The second interface is documented below in L</METHODS>, and lets you create
pretty little objects from this structure, which might or might not be more
convenient for your purposes.

When it's ready, that is.

=head1 HASH STRUCTURE

I hope this illustrates how the structure looks. Read it top down, but pretend
it's evalled bottom up.

	$structure = {
		test_files => $test_files,
	};

	$test_files = [
		$test_file,
		...
	];

	$test_file = {
		file => "t/filename.t",
		results => \%results;
		events => $events,

		# optional
		pre_diag => # diagnosis emitted before any test
	};

	%results = $strap->analyze_foo(); 

	$events = [
		{
			type => "test",
			num    => # the serial number of the test
			ok     => # a boolean
			result => # a string useful for display
			todo   => # a boolean
			line   => # the output line

			# pugs auxillery stuff, from the <pos:> comment
			pos    => # the place in the test file the case is in
		},
		{
			type => "bailout",
			reason => "blah blah blah",
		}
		...,
	];

That's basically it.

=cut
