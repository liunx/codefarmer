#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: extract.pl
#
#        USAGE: ./extract.pl
#
#  DESCRIPTION: extract .exp file
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (),
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 2012年10月14日 16时51分15秒
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use Data::Dumper;

# ===========================================================================
# filter layer routines
# ===========================================================================
sub filter_send_expect {
    my $file = shift;

    # @expects -- collect all of the send/expect pairs
    my @expects = ();

    # $mul_line -- join multiple lines into single line
    my $mult_line = "";

    # %element -- contain send/expect data and other flags
    my %element     = ();
    my $start_qoute = 0;

    # $element_key -- show current key when collect multiple lines data
    my $element_key = "";

    foreach my $line ( @{$file} ) {

        # we must care about that we are not in the qoute
        if ( $start_qoute == 0 ) {
            if ( $line =~ /^send --/ ) {

                # there's 2 condition that:
                # 1. the contents in single line;
                # 2. the contents in multiple lines, we should
                #    join them together.
                if ( $line =~ /"$/ ) {
                    $line =~ s/"$//g;
                    my @data = split( /"/, $line, 2 );
                    if ( scalar @data == 2 ) {
                        $element{send} = $data[1];
                    }
                    else {
                        die "split failed!\n";
                    }
                }
                else {
                    my @data = split( /"/, $line, 2 );
                    if ( scalar @data == 2 ) {
                        $mult_line .= $data[1];
                    }
                    else {
                        die "split failed!\n";
                    }
                    $element_key = "SEND";
                    $start_qoute = 1;
                }

            }
            elsif ( $line =~ /^expect -exact/ ) {

                # there's 2 condition that:
                # 1. the contents in single line;
                # 2. the contents in multiple lines, we should
                #    join them together.
                if ( $line =~ /"$/ ) {
                    $line =~ s/"$//g;
                    my @data = split( /"/, $line, 2 );
                    if ( scalar @data == 2 ) {
                        $element{expect} = $data[1];
                        my %href = %element;
                        push @expects, \%href;
                    }
                    else {
                        die "split failed!\n";
                    }
                }
                else {
                    my @data = split( /"/, $line, 2 );
                    if ( scalar @data == 2 ) {
                        $mult_line .= $data[1];
                    }
                    else {
                        die "split failed!\n";
                    }
                    $element_key = "EXPECT";
                    $start_qoute = 1;
                }

            }
        }
        else {
            if ( $line =~ /"$/ ) {
                $line =~ s/"$//g;
                $mult_line .= $line;
                if ( $element_key eq "SEND" ) {
                    $element{send} = $mult_line;
                }
                elsif ( $element_key eq "EXPECT" ) {

                    # expect means we got a send/expect pair
                    $element{expect} = $mult_line;
                    my %href = %element;
                    push @expects, \%href;
                }
                else {
                    die "Error: no element key defined!\n";
                }

                # reset temple variables
                $start_qoute = 0;
                $mult_line   = "";
            }
            else {
                $mult_line .= $line;
            }

        }
    }

    return \@expects;
}

# when the user press cr, we known that a command or something else
# should be sent to the terminal.
# let's try group the send/expect into cr group
sub filter_carriage_return {
    my @layer_cr      = ();
    my @cr_group      = ();
    my $layer_snd_exp = shift;
    my $flag_cr       = 0;
    foreach my $data ( @{$layer_snd_exp} ) {
        if ( !defined $data->{send} ) {
            push @cr_group, $data;
            my @ref_group = @cr_group;
            push @layer_cr, \@ref_group;
            @cr_group = ();
            next;
        }
        if ( $flag_cr == 0 ) {
            if ( $data->{send} =~ /\\r$/ ) {

                # just one line
                push @cr_group, $data;
                my @ref_group = @cr_group;
                push @layer_cr, \@ref_group;
                @cr_group = ();
            }
            else {
                $flag_cr = 1;
                push @cr_group, $data;
            }

        }
        else {
            if ( $data->{send} =~ /\\r$/ ) {
                push @cr_group, $data;
                my @ref_group = @cr_group;
                push @layer_cr, \@ref_group;
                @cr_group = ();
                $flag_cr  = 0;
            }
            else {
                push @cr_group, $data;
            }
        }
    }

    return \@layer_cr;
}

sub filter_ctrl_char {
    my $layer_cr        = shift;
    my @layer_ctrl_char = ();
    my %href_pair       = ();

    foreach my $ref_layer_cr ( @{$layer_cr} ) {
    	my ( $str_send, $str_expect );

        # process send/expect pair
        foreach my $ref ( @{$ref_layer_cr} ) {
			# if no send, we just ignore it
            if ( !defined $ref->{send} ) {
				$str_expect .= $ref->{expect};
				next;
            }

			# process backspace
			if ($ref->{send} =~ /\c?$/) {
				$ref->{send} =~ s/\c?$//g;
				$str_send .= $ref->{send};

				if ($ref->{expect} =~ /\cH\c[\\\[K/) {
					$str_send = substr($str_send, 0, length($str_send) - 1);
					# Yes, we should delete one letter
					$ref->{expect} =~ s/\cH\c[\\\[K//g;
					$str_expect .= $ref->{expect};
				}
				elsif ($ref->{expect} =~ /\cG$/) {
					# no letters to delelte
					$ref->{expect} =~ s/\cG$//g;
					$str_expect .= $ref->{expect};
				}
				else {
					$str_send .= $ref->{send};
					$str_expect .= $ref->{expect};
				}
			}
			else {
				$str_send .= $ref->{send};
				$str_expect .= $ref->{expect};
			}

        }

		$href_pair{send} = $str_send;
		$href_pair{expect} = $str_expect;
		my %href_data = %href_pair;
		push @layer_ctrl_char, \%href_data;
    }

	return \@layer_ctrl_char;
}

# ===========================================================================
# help routines
# ===========================================================================
sub show_data {
    my $expects = shift;
    foreach my $data ( @{$expects} ) {
        my $send   = $data->{send};
        my $expect = $data->{expect};
        if ( defined $send ) {
            print "$send\n";
        }

        if ( defined $expect ) {
            print "$expect\n";
        }
    }
}

# ===========================================================================
# main routine
# ===========================================================================
open FILE, "script.exp" or die $!;

# ============= raw data layer ===============
my @layer_raw_data = ();
while (<FILE>) {
    chomp;
    push @layer_raw_data, $_;
}
close FILE;

# ========== send/expect pair layer ==========
my $layer_snd_exp = filter_send_expect( \@layer_raw_data );

#print Dumper($layer_snd_exp);
my $layer_cr = filter_carriage_return($layer_snd_exp);
print Dumper($layer_cr);
my $layer_ctrl_char = filter_ctrl_char($layer_cr);
print Dumper($layer_ctrl_char);

