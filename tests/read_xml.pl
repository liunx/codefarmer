#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: read_xml.pl
#
#        USAGE: ./read_xml.pl  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2013年09月04日 11时13分32秒
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use XML::Simple;
use Data::Dumper;
use Getopt::Std;

#################### main #####################
my %options = ();
Getopt::Std::getopts('i:', \%options);

if (!defined $options{i}) {
	print "Usage: auto_work.pl -i xml...\n";
	exit 0;
}

my $simple = XML::Simple->new();
my $data   = $simple->XMLin($options{i}, KeyAttr => { function => 'name' }, ForceArray => [ 'workblock', 'work' ]);
# DEBUG
print ref $data, "\n";
print Dumper $data;
# END
