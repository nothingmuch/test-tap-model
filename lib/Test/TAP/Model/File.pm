#!/usr/bin/perl

package Test::TAP::Model::File;

use strict;
use warnings;

use Test::TAP::Model::Subtest;

use overload '""' => "name";

# TODO test this more thoroughly, probably with Devel::Cover

sub new {
	my $pkg = shift;
	my $struct = shift;
	bless \$struct, $pkg; # don't bless the structure, it's not ours to mess with
}

# predicates about the test file
sub ok { ${ $_[0] }->{results}{passing} }; *passed = \&ok;
sub nok { !$_[0]->ok }; *failed = \&nok;
sub bailed_out { die "todo" }
sub skipped { exists ${ $_[0] }->{results}{skip_all} };

# member data queries
sub name { ${ $_[0] }->{file} }

# utility methods for extracting tests.
sub subtest_class { "Test::TAP::Model::Subtest" }
sub mk_objs { my $self = shift; wantarray ? map { $self->subtest_class->new($_) } @_ : @_ }
sub _test_structs {
	grep { $_->{type} eq "test" } @{ ${ $_[0] }->{events} }
}
sub _c {
	my $self = shift;
	my $sub = shift;
	return shift if not wantarray and @_; # if we have a precomputed scalar
	$self->mk_objs(grep { &$sub } $self->_test_structs);
}

# queries about the test cases
sub planned { ${ $_[0] }->{results}{max} }; *max = \&planned; # only scalar context

sub cases { $_[0]->_c(sub { 1 }, ${ $_[0] }->{results}{seen}) }; *seen = *test_cases = *subtests = \&cases;
sub ok_tests { $_[0]->_c(sub { $_->{ok} }, ${ $_[0] }->{results}{ok}) }; *passed_tests = \&ok_tests;
sub nok_tests { $_[0]->_c(sub { !$_->{ok} }), ${ $_[0] }->{results}{seen} - ${ $_[0] }->{results}{ok}}; *failed_tests = \&nok_tests;
sub todo_tests { $_[0]->_c(sub { $_->{todo} }, ${ $_[0] }->{results}{todo}) }
sub skipped_tests { $_[0]->_c(sub { $_{skip} }, ${ $_[0] }->{results}{skip}) }
sub unexpectedly_succeeded_tests { $_[0]->_c(sub { $_{todo} and $_{actual_ok} }) }

sub ratio {
	my $self = shift;
	$self->ok_tests / $self->seen;
}

sub percentage {
	my $self = shift;
	sprintf("%.2f%%", 100 * $self->ratio);
}

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::Model::File - an object representing the TAP results of a single
test script's output.

=head1 SYNOPSIS

	my $f = ( $t->test_files )[0];
	
	if ($f->ok){ # et cetera
		print "happy happy joy joy!";
	}

=head1 DESCRIPTION

This is a convenience object, which is more of a library of questions you can
ask about the hash structure described in L<Test::TAP::Model>.

It's purpose is to help you query status concisely, probably from a templating
kit.

=head1 METHODS

=head2 Predicates About the File

=over 4

=item ok

=item passed

Whether the file as a whole passed

=item nok

=item failed

Or failed

=item skipped

Whether skip_all was done at some point

=item bailed_out

Whether test bailed out

=back

=head2 Methods for Extracting Subtests

=over 4

=item cases

=item subtests

=item test_cases

=item seen

In scalar context, a number, in list context, a list of L<Test::TAP::Model::Subtest> objects

=item max

=item planned

Just a number, of the expected test count.

=item ok_tests

=item passed_tests

Subtests which passed

=item nok_tests

=item failed_tests

Duh.

=item todo_tests

Subtests marked TODO.

=item skipped_tests

Test which are vegeterian.

=back

=cut
