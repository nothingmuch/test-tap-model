#!/usr/bin/perl

package Test::TAP::Model::File::Consolidated;
use base qw/Test::TAP::Model::File/;

use strict;
use warnings;

use List::Util ();

sub new {
	my $pkg = shift;
	bless [ @_ ], $pkg;
}

sub concat_aggr {
	my $self = shift;
	my $method = shift;

	wantarray ? (map { $_->$method } @$self) : List::Util::sum(map { scalar $_->$method } @$self);
}

sub boolean_aggr {
	my $self = shift;
	my $method = shift;

	$_->$method || return for (@$self);
	return 1;

}

BEGIN {
	# these subs are aggregated
	# the rest are inherited, because they apply to the aggregate versions
	for my $subname (qw/
		planned
		cases
		actual_cases
		ok_tests
		nok_tests
		todo_tests
		skipped_tests
		unexpectedly_succeeded_tests
	/) {
		no strict 'refs';
		*{$subname} = sub { $_[0]->concat_aggr($subname) };
	}

	for my $subname (qw/
		ok
		skipped
		bailed_out
	/) {
		no strict 'refs';
		*{$subname} = sub { $_[0]->boolean_aggr($subname) };
	}
}

sub name {
	my $self = shift; # currently broken, until _transpose_arrays is fixed
	$self->[0]->name
}

sub subfiles {
	my $self = shift;
	@$self;
}

sub consistent {
	my $self = shift;

	my ($head, @tail) = $self->subfiles;
	foreach my $tail (@tail) {
		return unless $head == $tail;
	}

	1;
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Test::TAP::Model::File::Consolidated - 

=head1 SYNOPSIS

	use Test::TAP::Model::File::Consolidated;

=head1 DESCRIPTION

=cut


