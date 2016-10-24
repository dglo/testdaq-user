#!/usr/bin/perl -w
#
# This script takes the output from `domhub xxx quickstatus` and parses
# which hubs have minor or major issues and then dyes the racks and hubs
# accordingly in green, yellow or red.
# At last, it prints a list of all hubs that have any issue; this list
# could be used as argument for RemoveDeploy.sh (copy & paste).
#
# 2016-08-31 -ck-`

use strict;
use POSIX qw(strftime);
use Term::ANSIColor;
$| = 1;

my %racks = ();
$racks{"01"} = [ 62, 54, 63, 45, 75, 76, 69, 70 ];
$racks{"02"} = [ 60, 68, 61, 44, 52, 53,  8, 16 ];
$racks{"03"} = [ 25, 35, 15, 24, 34, 51, 23, 33 ];
$racks{"04"} = [ 32, 41, 42, 43, 31, 79, 80, 22 ];
$racks{"05"} = [  2,  3,  9, 17, 26,  7, 14,  1 ];
$racks{"06"} = [ 20, 28, 37, 10,  4,  5, 11, 18 ];
$racks{"07"} = [ 21, 29,  6, 12, 19, 27, 36, 13 ];
$racks{"08"} = [ 67, 57, 47, 59, 49, 50, 40, 30 ];
$racks{"09"} = [ 71, 64, 74, 66, 48, 39, 38, 58 ];
$racks{"10"} = [ 65, 56, 46, 78, 72, 73, 55, 77 ];
$racks{"11"} = [ 208, 207, 206, 205, 204, 203, 202, 201 ];
$racks{"12"} = [ 209, 210, 211 ];
$racks{"15"} = [ 83, 82, 81, 86, 85, 84 ];

my $max_failed_doms = 2;


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub number2hostname {
#-------------------------------------------------------------------------------
    my $n = shift;

    return sprintf("ichub%02d", $n) if $n < 200;
    return sprintf("ithub%02d", $n - 200) if $n >= 200;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub determine_hub_status {
#-------------------------------------------------------------------------------
    my ($hub_status, $hubs_msg) = @_;

    my $read = 0;

    
    # read STDIN ...
    while (my $line = <STDIN>) {
    
        # copy everything to STDOUT
        print $line;
    
        # after the line starting with "HUBS=" start parsing
        $read = 1 if $line =~ m/^HUBS=/;
        next unless $read;
    
        # collect all messages per hub
        $hubs_msg->{$1} .= $line
            if $line =~ m/((ic|it)hub\d\d)/;
    
        # parse the lines and determine the severity of the issue
        if ($line =~ m/((ic|it)hub\d\d) : There are (\d+) Missing DOMs\./) {
            $hub_status->{$1} = ($3 <= $max_failed_doms) ? 1 : 2;
        }
    
        if ($line =~ m/((ic|it)hub\d\d) : Unexpected # of communicating DOMs: expected (\d+); found (\d+)/) {
            $hub_status->{$1} = ($3 - $4 <= $max_failed_doms) ? 1 : 2;
        }
    
        $hub_status->{$1} = 2
            if $line =~ m/Hub did not respond: sps-([a-z0-9]+)\./;
        $hub_status->{$1} = 2
            if $line =~ m/((ic|it)hub\d\d) : Unexpected # of DOR cards/;
        $hub_status->{$1} = 2
            if $line =~ m/((ic|it)hub\d\d) : Unexpected # of Quads plugged in/;
        
    }

}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub determine_rack_status {
#-------------------------------------------------------------------------------

    my ($hubs) = @_;

    my %rack_status = ();

    foreach my $rack (sort keys %racks) {
        my ($g, $y, $r) = (0, 0, 0);

        # count the number of green, yellow and red hubs in this rack
        foreach (@{$racks{$rack}}) {
            my $host = number2hostname($_);
            $g++ if $hubs->{$host} == 0;
            $y++ if $hubs->{$host} == 1;
            $r++ if $hubs->{$host} == 2;
        }

        my $status = 0;
        if ($y == 0 and $r == 0) {
            $status = 0;    # all green -> rack is green
        }
        elsif ($g == 0 and $y == 0) {
            $status = 2;    # all red   -> rack is red
        }
        else {
            $status = 1;    # otherwise yellow
        }

        $rack_status{$rack} = $status;
    }

    return \%rack_status;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub print_color {
#-------------------------------------------------------------------------------
    my ($color, $str, $n) = @_;

    my $c = ($color == 0) ? "green"
          : ($color == 1) ? "yellow"
          : ($color == 2) ? "red"
          :                 "white";

    return color($c) . sprintf($str, $n) . color("reset");
}

#-------------------------------------------------------------------------------
# TODO currently just playing around with html output ...
#-------------------------------------------------------------------------------
sub html_output {
#-------------------------------------------------------------------------------


    my ($hubs, $hubs_msg_ref, $rack_status) = @_;

    # copy the hash since we don't want to change it in the main program
    my %hubs_msg = %$hubs_msg_ref;

    foreach (keys %hubs_msg) {
        $hubs_msg{$_} =~ s/>/&gt;/g;
        $hubs_msg{$_} =~ s/</&lt;/g;

        $hubs_msg{$_} = "No messages; all good." if $hubs_msg{$_} eq '';
        $hubs_msg{$_} = "<b>=== $_ ===</b>\n" . $hubs_msg{$_};

        $hubs_msg{$_} =~ s/\n/<br>\n/g;
    }

    my $time = time();

    open(HTML, '>', 'rack_layout.html');
    print HTML <<"EOF";
<!DOCTYPE html PUBLIC "-?//W3C//DTD HTML 4.01 Transitional//EN"
      "http://www.w3.org/TR/html4/loose.dtd">

<html>
<head>
  <link rel="stylesheet" type="text/css" href="icl.css">
  <script type="text/javascript" src="age.js"></script>
  <script type="text/javascript">
    time = $time;
  </script>
</head>
<body>
EOF

    print HTML "<table>\n";

    my @rack_numbers
        = reverse qw(01 02 03 04 x 05 06 07 08 09 x 10 11 12 x 15);

    print HTML "<tr>\n";
    for my $rack (@rack_numbers) {
        if ($rack eq 'x') {
            print HTML "  <th class=\"column\">&nbsp;</td>\n";
            next;
        }
        my $class = ($rack_status->{$rack} == 0) ? 'ok'
                  : ($rack_status->{$rack} == 1) ? 'minor'
                  :                                'major';
        print HTML "<th class=\"rack $class\">Rack $rack</th>\n";
    }
    print HTML "</tr>\n";

    for my $row (0 .. 7) {
        print HTML "<tr>\n";
        for my $rack (@rack_numbers) {
            if ($rack eq 'x') {
                print HTML "  <td class=\"column\">&nbsp;</td>\n";
                next;
            }
            if (not defined $racks{$rack}->[$row]) {
                print HTML "  <td class=\"nohub\">&nbsp;</td>\n";
                next;
            }

            my $host = number2hostname($racks{$rack}->[$row]);
            my $class = ($hubs->{$host} == 0) ? 'ok'
                      : ($hubs->{$host} == 1) ? 'minor'
                      :                         'major';
            print HTML "  <td class=\"hub $class rack$rack tip\">$host"
                     . "<span>$hubs_msg{$host}</span>"
                     . "</td>\n";
        }
        print HTML "</tr>\n";
    }

    my $date = strftime("%d-%m-%Y %H:%M:%S", localtime(time));
    print HTML <<"EOF";
</table>

<br>
Correct as of: $date<br>
<br>
Age: <span id="age">&nbsp;</span>

</body>

</html>
EOF
    close(HTML);

}

#-------------------------------------------------------------------------------
# prints the ICL with racks in top-bottom layout
#-------------------------------------------------------------------------------
sub terminal_racks_tb {
#-------------------------------------------------------------------------------

    my ($hubs, $rack_status) = @_;

    my @rack_numbers
        = reverse qw(01 02 03 04 x 05 06 07 08 09 x 10 11 12 x 15);

    print "\n";
    print "----- Rack Layout: -----\n";
    print "\n";
    
    # print the rack numbers as the header of the table
    for my $rack (@rack_numbers) {
        if ($rack eq 'x') {
            print " XX ";
            next;
        }
        print print_color($rack_status->{$rack}, " %s ", "R$rack");
    }
    print "\n";

    # print all 8 rows
    for my $row (0 .. 7) {

        print "=" x 78 . "\n" if $row == 0;
        print "-" x 78 . "\n" if $row == 4;

        for my $rack (@rack_numbers) {
            if ($rack eq 'x') {
                print " XX ";
                next;
            }
            if (not defined $racks{$rack}->[$row]) {
                print "     ";
                next;
            }

            my $hub_number = $racks{$rack}->[$row];
            my $host = number2hostname($hub_number);
            print print_color($hubs->{$host}, " %3d ", $hub_number);
        }
        print "\n";
    }


}

#-------------------------------------------------------------------------------
# prints the ICL with racks in left-right layout
#-------------------------------------------------------------------------------
sub terminal_racks_lr {
#-------------------------------------------------------------------------------
    my ($hubs, $rack_status) = @_;

    print "\n";
    print "----- Rack Layout: -----\n";
    print "\n";
    
    foreach my $rack (sort keys %racks) {
    
        print print_color($rack_status->{$rack}, "Rack %2d", $rack);
        print ": ";
    
        foreach (@{$racks{$rack}}) {
            my $host = number2hostname($_);
            print print_color($hubs->{$host}, "%2d ", $_);
        }
    
        print "\n";
    }
    
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub terminal_issues_lists {
#-------------------------------------------------------------------------------
    my ($hubs) = @_;

    print "\n";
    print "----- Complete list of hubs with issues: -----\n";
    print "\n";
    print "Minor issues:\n";
    foreach my $i (1 .. 86, 201 .. 211) {
        print "$i " if $hubs->{number2hostname($i)} == 1;
    }
    print "\n";
    print "\n";
    print "Major issues:\n";
    foreach my $i (1 .. 86, 201 .. 211) {
        print "$i " if $hubs->{number2hostname($i)} == 2;
    }
    print "\n";
    print "\n";
    print "Any issue:\n";
    foreach my $i (1 .. 86, 201 .. 211) {
        print "$i " if $hubs->{number2hostname($i)} != 0;
    }
    print "\n";
}



################################################################################
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#   M a i n
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
################################################################################

my %hub_status = ();
$hub_status{number2hostname($_)} = 0 foreach (1 .. 86, 201 .. 211);

my %hubs_msg = ();
$hubs_msg{number2hostname($_)} = '' foreach (1 .. 86, 201 .. 211);


#-------------------------------------------------
# parse what's coming from STDIN and calculate status from this
determine_hub_status(\%hub_status, \%hubs_msg);

my $rack_status = determine_rack_status(\%hub_status);


#-------------------------------------------------
# output

#html_output(\%hub_status, \%hubs_msg, $rack_status);

#terminal_racks_lr(\%hub_status, $rack_status);
terminal_racks_tb(\%hub_status, $rack_status);

terminal_issues_lists(\%hub_status);
