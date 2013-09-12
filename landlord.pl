#!/usr/bin/env perl 
#
# landlord -- this is the main server
#

use strict;
use warnings;
use utf8;

use Data::Dumper;
use IO::Select;
use IO::Socket;
use Time::HiRes qw(usleep gettimeofday);
use Digest::MD5 qw(md5_hex);
use Fcntl;
use POSIX qw(:errno_h :sys_wait_h);

# define the constant scala
use constant TIMEOUT => (2 * 1000 * 1000);

# it's better to read data at one time.
use constant BUFLEN => (1024 * 1024);

my $keep_loop = 1;
my $lsn = IO::Socket::INET->new(Listen => 1, LocalPort => 9090) 
	or die $!;
my $sel = IO::Select->new($lsn);

$SIG{INT} = sub {
	print "interrupt...\n";
	$keep_loop = 0;
	$lsn->close();
};

$SIG{CHLD} = sub {
	my $kid;
	do  {
		$kid = waitpid(-1, WNOHANG);
	} while ($kid > 0);
};

#############################################################################
# main loop
#############################################################################
while($keep_loop) {
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
				$sel->remove($fh);
				$fh->close;
				next;
			}

			task_scheduler($total_data, $fh);

		}
	}

}

$lsn->close();

#############################################################################
# subroutines
#############################################################################
my %tasks = ();
# we'll do 3 task:
# 1. get use command, 2. fork farmer process, 3 send command to farmer process
sub task_scheduler {
	my $data = shift;
	my $fh = shift;

	print $data;
	# add json parser

	if ($data eq "hellouser\n") {
		# we'll assign a md5 id per data/child process
		my $id = md5_hex(gettimeofday());
		$tasks{$id} = $data;

		# now, we'll fork a child to do the work
		my $pid = fork();
		if ($pid) {
			;
		}
		elsif (undef $pid) {
			print "fork failed!\n";
		}
		else {
			local $SIG{CHLD} = "IGNORE";
			exec('./farmer.pl', '-h127.0.0.1', '-p9090', '-Ptcp', "-i$id");
		}
	}
	elsif ($data eq "farmer") {
		print "get data from farmer...\n";
	}
}
