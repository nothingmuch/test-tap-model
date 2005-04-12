#!/usr/bin/perl

package Test::TAP::Model::Subtest;

use strict;
use warnings;

use overload '""' => "str";

use Carp qw/croak/;

sub new {
	my $pkg = shift;
	my $struct = shift;

	croak "eek! You can't bless non test events into $pkg" unless $struct->{type} eq "test";
	
	bless \$struct, $pkg; # don't bless the structure, it's not ours to mess with
}

sub str { ${ $_[0] }->{result} }

# predicates about the case
sub ok { ${ $_[0] }->{ok} }; *passed = \&ok;
sub nok { !$_[0]->ok }; *failed = \&nok;
sub skipped { ${ $_[0] }->{skip} }
sub todo { ${ $_[0] }->{todo} }

# member data extraction
sub diag { ${ $_[0] }->{diag} }
sub line { ${ $_[0] }->{line} }
sub reason { ${ $_[0] }->{reason} } # for skip or todo

# pugs specific
sub pos { ${ $_[0] }->{pos} }

# heuristical
sub test_file { $_[0]->pos =~ /(?:file\s+|^)?(\S+)/ and $1 }; # maybe use Regexp::Common for quoted crap?
sub test_line { $_[0]->pos =~ /line\s+(\d+)/i and $1 }
sub test_column { $_[0]->pos =~ /column?\s+(\d+)/ and $1 }

__PACKAGE__

__END__

=pod

=head1 NAME

Test::TAP::Model::Subtest - 

=head1 SYNOPSIS

	use Test::TAP::Model::Subtest;

=head1 DESCRIPTION

=cut
