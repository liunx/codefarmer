#!/usr/bin/env perl 
#
# farmer -- this is worker code
#

use strict;
use warnings;
use utf8;

use IO::Socket::INET;
use Getopt::Std;

my %options = ();
# h -- host name, p -- port, P -- protocol, i -- id
Getopt::Std::getopts('h:p:P:i:', \%options);

my ($sock, $csock);

#######################################################################
# main loop
#######################################################################
$sock = IO::Socket::INET->new(
	PeerHost => $options{h},
	PeerPort => $options{p},
	Proto => $options{P},
) or die "ERROR in Socket creation: $!\n";

# send id to server
$sock->send("$options{i}\n");

my $data = "";

# read command from landlord
while (my $line = <$sock>) {
	$data .= $line;
}

main_loop($data);

$sock->close();


#######################################################################
# subroutines
#######################################################################
sub main_loop {
	my $data = shift;

	# parse json commands
	print $data, "\n";
}
