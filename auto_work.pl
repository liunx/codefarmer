#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: auto_work.pl
#
#        USAGE: ./auto_work.pl  
#
#  DESCRIPTION: auto_work with expect
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2013年09月03日 17时09分13秒
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Expect;
use XML::Simple;
use Data::Dumper;

my $timeout = 2;
my $flags_timeout = 0;
my $flags_eof = 0;

my $simple = XML::Simple->new();
my $data   = $simple->XMLin('telnet.xml');

## subroutines
# we must care for the failure
sub expect_handler {
	my $fh = shift;
	my $params = shift;

	# make a check for flags
	my $answer = $params->{answer};
	# the xml will output string, so we had to
	# recover the control characters
	$answer =~ s/\\n/\n/g;
	$answer =~ s/\\c]/\c]/g;
	$fh->send($answer);
}

sub expect_eof {
	$flags_eof = 1;
	die "ERROR: EOF!\n";
}

sub expect_timeout {
	$flags_timeout = 1;
	die "ERROR: TIMEOUT!\n";
}

############# main ############
my $exp = Expect->new();
$exp->raw_pty(0);

foreach my $item (@{$data->{work}}) {
	# fetch work pipe line
	if ($item->{type} eq "spawn") {
		$exp->spawn($item->{command}) or die $!;
	}
	elsif ($item->{type} eq "expect") {
		$exp->expect(
			$timeout, 
			[ qr($item->{pattern}), \&expect_handler, $item ],
			[ eof => \&expect_eof ],
			[ timeout => \&expect_timeout ]
		);
	}
	else {
		print "Unknown type!\n";
	}
}

$exp->interact();
