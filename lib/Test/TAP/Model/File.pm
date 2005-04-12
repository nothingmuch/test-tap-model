#!/usr/bin/perl

package Test::TAP::Model::File;

use strict;
use warnings;

# TODO test this more thoroughly, probably with Devel::Cover

sub new {
	my $pkg = shift;
	my $struct = shift;
	bless \$struct, $pkg; # don't bless the structure, it's not ours to mess with
}

# predicates about the test file
sub ok { ${ $_[0] }->{results}{passed} }; *passed = \&ok;
sub nok { !$_[0]->ok }; *failed = \&nok;
sub bailed_out { die "todo" }
sub skipped { ${ $_[0] }->{results}{skip} };


# utility methods for extracting tests.
sub mk_objs { shift; wantarray ? map { Test::TAP::Model::Case->new($_) } @_ : @_ }
sub _test_structs {
	grep { $_->{type} = "test" } @{ ${ $_[0] }->{events} }
}
sub _c {
	my $self = shift;
	my $sub = shift;
	$self->mk_objs(grep { &$sub } $self->_test_structs);
}

# queries about the test cases
sub planned { ${ $_[0] }->{results}{max} }; *max = \&planned; # only scalar context
sub cases {
	wantarray
		? $_[0]->mk_objs($_[0]->_test_structs)
		: ${ $_[0] }->{results}{seen}
}
*seen = *test_cases = *subtests = \&cases;

sub ok_tests { $_[0]->_c(sub { $_->{ok} and not $_->{skip} }) }; *passed_tests = \&ok_tests;
sub nok_tests { $_[0]->_c(sub { !$_->{ok} }) }; *failed_tests = \&nok_tests;
sub todo_tests { $_[0]->_c(sub { $_->{todo} }) }
sub skipped_tests { $_->[0]->_c(sub { $_{skip} }) }

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
