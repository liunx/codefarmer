#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: test.pl
#
#        USAGE: ./test.pl  
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
#      CREATED: 2012年10月14日 12时03分45秒
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use utf8;

my @plugins = ();
# load all plugins
my @files = <./plugins/*>;
foreach my $file (@files) {
	my $obj = require $file;
	push @plugins, $obj;
}

foreach my $obj (@plugins) {
	$obj->hello();
}
