#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: select.pl
#
#        USAGE: ./select.pl  
#
#  DESCRIPTION: for non-block select 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2012年09月24日 12时03分25秒
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Data::Dumper;
use IO::Select;
use IO::Socket;
use Time::HiRes qw(usleep);
use Fcntl;
use POSIX qw(:errno_h);

# define the constant scala
use constant TIMEOUT => (2 * 1000 * 1000);

# it's better to read data at one time.
use constant BUFLEN => (1024 * 1024);

my $lsn = IO::Socket::INET->new(Listen => 1, LocalPort => 9090) 
	or die $!;
my $sel = IO::Select->new($lsn);

my $sleep_time = 100;

# time out 2s
my $time_out = 0;

while(1) {
	# -----------------------------------------------------------------------
	# process the incoming events
	# -----------------------------------------------------------------------
	my @ready = $sel->can_read();
	foreach my $fh (@ready) {
		if($fh == $lsn) {
			# Create a new socket
			my $new = $lsn->accept;
			# make it non-blocking
			fcntl($new, F_SETFL, O_NONBLOCK);
			$sel->add($new);
		}
		else {
			# Process socket
			# Maybe we have finished with the socket
			my $total_data = undef;
			# get all of data
			while (my $rv = sysread($fh, my $data, BUFLEN)) {
				$total_data .= $data;
			}

			# 0 means no data but remote pair broken.
			if (!defined($total_data)) {
				print "Remote pair broken...\n";
				$sel->remove($fh);
				$fh->close;
				next;
			}

			# TODO Here we can add process subroutines
			print $total_data;

		}
	}

	# -----------------------------------------------------------------------
	# do the normal affair
	# -----------------------------------------------------------------------

	if ($time_out > TIMEOUT) {
		$time_out = 0;
	}

	usleep($sleep_time);
	$time_out += $sleep_time;
}
