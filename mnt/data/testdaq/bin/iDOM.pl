#!/usr/bin/perl

print "usage: iDOM.pl [card] [pair] [AorB] \n";

$argcard = "all";
$argpair = "all";
$argAorB = "all";

if (defined($ARGV[0])) {
    $argcard    = $ARGV[0];
}
if (defined($ARGV[1])) {
    $argpair    = $ARGV[1];
}
if (defined($ARGV[2])) {
    $argAorB    = $ARGV[2];
    $argAorB  =~ tr/a-z/A-Z/;
}

$commdoms = 0;
$iceboots = 0;
$configboots = 0;
$busies = 0;
$stfservs = 0;
$flagdor = 0;

system ("mkdir -p /mnt/data/testdaq/Results/iDOM/");
chdir "/mnt/data/testdaq/bin/";
#system("rm -f iDOM.dat") if (-e "monitor.dat");
$dorcards = 0;

#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdat) = localtime(time());
#$str = "$year"."$mon"."$mday"."$hour"."$min"."$sec";

if ($argcard eq "all") {
    $card = 0;
    $argcardmax = 8;
} else {
    $card = $argcard;
    $argcardmax = $argcard + 1;
}

$headerflag = 0;
while ($card<$argcardmax) {
    if ($argpair eq "all") {
        $pair = 0;
        $argpairmax = 4;
    } else {
        $pair = $argpair;
        $argpairmax = $argpair + 1;
    }                                                                                                                         
    while ($pair<$argpairmax) {

        if ($argAorB eq "all") {
            $dom = 1;
            $argdommax = 3;
        } else {
            if ($argAorB eq "A") { 
                $dom = 2;
            } else {
                $dom = 1;
            }
            $argdommax = $dom + 1;
        }

        while ($dom<$argdommax) {
            if ($dom == 1) { 
                $DOM = "B";
            }
            $port = 5000 + 8*$card + 2*$pair + $dom;
            $quad = 2 + $card*2 + int($pair/2);
            if ($quad < 10) { $quad = "_"."$quad" };
            if ($dom == 2) { 
                $DOM = "A";
            }
            $commstring = "    ";
            $idstring = "            ";
            $currentstring = "     ";


            if ( -e "/proc/driver/domhub/card$card/pair$pair/pwr" ) {
                open (IN,"/proc/driver/domhub/card$card/pair$pair/pwr");
                @page = (<IN>);
                close(IN);
                $poweroff = 0;
                foreach (@page) {
                    if (/is off/) {
                        $poweroff = 1; 
                    }
                }
            }

            if ($poweroff == 0) {
                if ( -e "/proc/driver/domhub/card$card/pair$pair/dom$DOM/is-communicating" ) {
                    open (IN,"/proc/driver/domhub/card$card/pair$pair/dom$DOM/is-communicating");
                    @page = (<IN>);
                    close(IN);
                    foreach (@page) {
                        if (/is communicating/) {
                            $commstring = "COMM";
                            $commdoms = $commdoms + 1;
                        } else {
                            $commstring = "    ";
                        }
                    }
                }
#print "got through is-comm\n";

                if ($headerflag == 0) {
                    $headerflag = 1;
                }

                $position = $port - 5000;
                if ($position < 10) { $position = "0"."$position" };
                $location = "$string"."-"."$position";

                if ($dom == 2) { $domab = "a"  };
                if ($dom == 1) { $domab = "b"  };
                if ($commstring eq "COMM") {

                    $DOR = "$argcard$argpair$argAorB";
                    print "DOR = $DOR \n";
                    system("se $DOR < /mnt/data/testdaq/bin/ld-spi516.txt");
                    print " we se'd $DOR, now for the hard part... \n";

#$yinc=system("yinc=$(echo 'send \"$0200 $90081090 ! 50000 usleep $0000 $90081090 ! 500 usleep $90081094 @ $3fff and . drop\r\" expect \"^>\"' | se $DOR | tr '\r' '\n' | grep '^[0-9]')");
#$yinc=system("yinc=$(echo 'send \"$0200 $90081090 ! 50000 usleep $0000 $90081090 ! 500 usleep $90081094 @ $3fff and . drop\r\" expect \"^>\"' | se $DOR )");

                    system("rm -f /tmp/iDOM.dat");
                    system("vccDOM.sh $DOR > /tmp/iDOM.dat");
                    open(IN,"/tmp/iDOM.dat");
                    @page = (<IN>);
                    close(IN);

                    foreach (@page) {
                        $line= $_;
                        chop $line;
                        $vcc=$line;
                    }

                    $vcc=$vcc*0.30518;
                    print "VCC = $vcc \n";

                    system("rm -f /tmp/iDOM.dat");
                    system("tempDOM.sh $DOR > /tmp/iDOM.dat");

                    open(IN,"/tmp/iDOM.dat");
                    @page = (<IN>);
                    close(IN);

                    foreach (@page) {
                        $line= $_;
                        chop $line;
                        $temp=$line;
                    }
                    $temp = (($temp-1278)* -0.47) + 25;
                    print "temp = $temp \n";

                    system("rm -f /tmp/iDOM.dat");
                    system("xincDOM.sh $DOR > /tmp/iDOM.dat");
                    open(IN,"/tmp/iDOM.dat");
                    @page = (<IN>);
                    close(IN);

                    foreach (@page) {
                        $line= $_;
                        chop $line;
                        $xinc=$line;
                    }
                    if ($xinc >= 8192) {
                        $xinc = (16384 - 1 - $xinc ) * -0.025
                    } 
                    else {
                        $xinc = $xinc * 0.025; 
                    }
                    print "xinc = $xinc \n";

                    system("rm -f /tmp/iDOM.dat");
                    system("yincDOM.sh $DOR > /tmp/iDOM.dat");
                    open(IN,"/tmp/iDOM.dat");
                    @page = (<IN>);
                    close(IN);

                    foreach (@page) {
                        $line= $_;
                        chop $line;
                        $yinc=$line;
                    }
                    if ($yinc >= 8192) {
                        $yinc = (16384 - 1 - $yinc ) * -0.025
                    } 
                    else {
                        $yinc = $yinc * 0.025;
                    }
                    print "yinc = $yinc \n";
                    
                    

                } # DOM is communicating
            }

            $dom = $dom + 1;
        }
        $pair = $pair + 1;
    }
    $card = $card + 1; 
}


print "\n";

#if ($message ne "") {
#  print "software: $message \n\n";
#}
#if ($dbflag == 1) {
#  close (OUT);
#}
printf("-------------------------------------------------------------------------------\n");

my $day=(localtime)[3];
my $year=(localtime)[5]-100;
my $month=(localtime)[4]+1;
my $hour=(localtime)[2];
my $min=(localtime)[1];
my $sec=(localtime)[0];
my $tag=sprintf("%02d%02d%02d.%02d%02d%02d",$year,$month,$day,$hour,$min,$sec);

open (OUT,">>/mnt/data/testdaq/Results/iDOM/iDOM.dat");

$message = sprintf("%s %3s %5d %7.3f %7.3f %7.3f",$tag,$DOR,$vcc,$temp,$xinc,$yinc);

print OUT "$message\n";
close (OUT);

