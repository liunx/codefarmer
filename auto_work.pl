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
use Getopt::Std;

my $timeout = 20;
my $flags_timeout = 0;
my $flags_eof = 0;

#################### main #####################
my %options = ();
Getopt::Std::getopts('i:', \%options);

if (!defined $options{i}) {
	print "Usage: auto_work.pl -i xml...\n";
	exit 0;
}

my $simple = XML::Simple->new();
my $data   = $simple->XMLin($options{i});

my $exp = Expect->new();
$exp->raw_pty(0);
$exp->debug(0);

main_loop($data);

$exp->interact();

###########################################################################
## subroutines
###########################################################################
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

sub main_loop {
	my $data = shift;

	foreach my $item (@{$data->{work}}) {
		# fetch work pipe line
		if ($item->{type} eq "spawn") {
			$exp->spawn($item->{command}) or die $!;
		}
		elsif ($item->{type} eq "expect") {
			$exp->expect(
				$timeout, 
				[ "-re", qr($item->{pattern}), \&expect_handler, $item ],
				[ eof => \&expect_eof ],
				[ timeout => \&expect_timeout ]
			);

			# we need to sleep a bit to avoid a faster reponse than
			# the target program, or we'll stuck.
			if (defined $item->{sleep}) {
				sleep($item->{sleep});
			}
		}
		else {
			print "Unknown type!\n";
		}

	}
}

