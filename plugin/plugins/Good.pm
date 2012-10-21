package Good;
#
#===============================================================================
#
#         FILE: Test.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 2012年10月14日 12时02分49秒
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(hello);
 
sub hello {
	my $pack = shift;
	print "hello from $pack\n";
}


__PACKAGE__;
