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

# hash the workblocks
my %workblocks = ();

#################### main #####################
my %options = ();
Getopt::Std::getopts('i:', \%options);

if (!defined $options{i}) {
	print "Usage: auto_work.pl -i xml...\n";
	exit 0;
}

my $simple = XML::Simple->new();
my $data   = $simple->XMLin($options{i}, KeyAttr => { function => 'name' }, ForceArray => [ 'workblock', 'work', 'pattern' ]);

my $exp = Expect->new();
$exp->raw_pty(0);
$exp->debug(0);

hash_workblocks($data->{workblock});

# we should get the main entry, first, then begin
# the work from main.
if (!defined $workblocks{main}) {
	die "No main block found!";
}
my $main = $workblocks{main};
main_loop($main);

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

	# check action
	print "action: $params->{action}->{type}\n";
}

sub expect_eof {
	$flags_eof = 1;
	die "ERROR: EOF!\n";
}

sub expect_timeout {
	$flags_timeout = 1;
	die "ERROR: TIMEOUT!\n";
}

sub hash_workblocks {
	my $wblocks = shift;
	if (ref($wblocks) ne "ARRAY") {
		die "No workblocks found!";
	}

	foreach my $i (@{$wblocks}) {
		$workblocks{$i->{name}} = $i;
	}

}

sub main_loop {
	my $data = shift;

	foreach my $item (@{$data->{work}}) {
		# fetch work pipe line
		if ($item->{type} eq "spawn") {
			$exp->spawn($item->{command}) or die $!;
		}
		elsif ($item->{type} eq "expect") {
			# add pattern array to expect
			my @patterns = ();
			foreach my $i (@{$item->{pattern}}) {
				push @patterns, [ "-re", qr($i->{filter}), \&expect_handler, $i ];
			}

			push @patterns, [ eof => \&expect_eof ];
			push @patterns, [ timeout => \&expect_timeout ];
			$exp->expect(
				$timeout, 
				@patterns,
				# [ "-re", qr($item->{pattern}), \&expect_handler, $item ],
				# [ eof => \&expect_eof ],
				# [ timeout => \&expect_timeout ]
			);

			# we need to sleep a bit to avoid a faster response than
			# the target program, or we'll stuck.
			if (defined $item->{sleep}) {
				sleep($item->{sleep});
			}
		}
		elsif ($item->{type} eq "callblock") {
			my $item = $workblocks{$item->{name}};
			main_loop($item);
		}
		else {
			print "Unknown type!\n";
		}

	}
}

