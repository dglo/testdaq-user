#!/usr/bin/perl

#
# by mark krasberg, u of wisconsin, after a good idea from Hagar
#
# coded in (small) part by Victor Bittorf
#

$type = $ARGV[0];

if ( !defined($type) ) {
	print
"argument should be 'Configb' or 'Iceboot' or 'DOMApp' or 'Multimo' or 'Unknown' or 'pDown' or 'pUpOn' or 'pUpIce' \n";
	$type = "Iceboot";
	exit();
}

if (   ( $type ne "Configb" )
	&& ( $type ne "Iceboot" )
	&& ( $type ne "DOMApp" )
	&& ( $type ne "Multimo" )
	&& ( $type ne "Unknown" )
	&& ( $type ne "pDown" )
	&& ( $type ne "pUpOn" )
	&& ( $type ne "pUpIce" )
	&& ( $type ne "pDownsp" )
	&& ( $type ne "pUpsp" ) )
{
	print
"argument should be 'Configb' or 'Iceboot' or 'DOMApp' or 'Multimo' or 'Unknown' or 'pDown' or 'pUpOn' or 'pUpIce' \n";
	$type = "Iceboot";
	exit();
}

$t1970 = time();

$tGMT = gmtime($t1970);

#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdat) = @a;

print "$tGMT time is ( $t1970 seconds ) \n";

#print " $sec $min $hour \n";

$dir = "$ENV{HOME}/Results/Current";
if ( -e "$dir" ) {
}
else {
	system("mkdir $dir");
}

#open (OUT,">>$file");

$domn = -1;
while ( $domn < 64 ) {
	$domn = $domn + 2;
	$card = int( ( $domn - 1 ) / 8 );
	$pair = int( ( ( $domn - 1 ) - ( $card * 8 ) ) / 2 );
	$AorB = ( $domn - 1 ) - ( $card * 8 ) - ( $pair * 2 );
	$AorB = 1 - $AorB;

	# print "$domn, $card, $pair, $AorB \n";

	$proc = "/proc/driver/domhub/card$card/pair$pair/is-plugged";
	if ( -e "$proc" ) {

		#print "reading $card, $pair, $AorB    $proc \n";
		$AB = "C";
		if ( $AorB eq 0 ) { $AB = "A" }
		if ( $AorB eq 1 ) { $AB = "B" }
		if ( $AB eq "C" ) {
			print " oh no!!! This is not possible \n\n";
		}

		$proccomm =
		  "/proc/driver/domhub/card$card/pair$pair/dom$AB/is-communicating";
		$proccommA =
		  "/proc/driver/domhub/card$card/pair$pair/domA/is-communicating";
		$proccommB =
		  "/proc/driver/domhub/card$card/pair$pair/domB/is-communicating";

		open( IN, "$proccomm" );
		@page = (<IN>);
		foreach (@page) {
			if (/is communicating/) {
				$iscomm = " is communicating";
			}
			else {
				$iscomm = "not communicating";
			}
		}

		open( IN, "$proccommA" );
		@page = (<IN>);
		foreach (@page) {
			if (/is communicating/) {
				$iscommA = " is communicating";
			}
			else {
				$iscommA = "not communicating";
			}
		}

		open( IN, "$proccommB" );
		@page = (<IN>);
		foreach (@page) {
			if (/is communicating/) {
				$iscommB = " is communicating";
			}
			else {
				$iscommB = "not communicating";
			}
		}

		$procserial = "/proc/driver/domhub/card$card/test-log";
		open( IN, "$procserial" );
		@page = (<IN>);

		foreach (@page) {
			( $junk, $serial ) = split( "Serial number: ", $_ );
			chop $serial;
			last;
		}

		$proccurrent = "/proc/driver/domhub/card$card/pair$pair/current";
		open( IN, "$proccurrent" );
		@page = (<IN>);

		foreach (@page) {
			( $junk,    $current ) = split( "is", $_ );
			( $current, $junk )    = split( "mA", $current );
		}

		$procvoltage = "/proc/driver/domhub/card$card/pair$pair/voltage";
		open( IN, "$procvoltage" );
		@page = (<IN>);

		foreach (@page) {
			( $junk,    $voltage ) = split( "is",    $_ );
			( $voltage, $junk )    = split( "Volts", $voltage );
		}

		#$current = real($current);
		#$voltage = real($voltage);
		$power = $voltage * $current;
		$power = $power / 1000.;

		if (   ( $type eq "Iceboot" )
			|| ( $type eq "Multimo" )
			|| ( $type eq "DOMApp" )
			|| ( $type eq "Unknown" )
			|| ( $type eq "pDown" )
			|| ( $type eq "pUpOn" )
			|| ( $type eq "pUpIce" )
			|| $type eq "pUpsp"
			|| $type eq "pDownsp" )
		{
			$idprocA = "";
			$idprocB = "";
			$idprocA = "/proc/driver/domhub/card$card/pair$pair/domA/id";
			$idprocB = "/proc/driver/domhub/card$card/pair$pair/domB/id";

			#print "hi1\n";

			if ( $iscommA eq " is communicating" ) {
				open( IN, "$idprocA" );
				@page = (<IN>);
				foreach (@page) {
					$idA = $_;
					chop $idA;
					( $junk, $idA ) = split( "is ", $idA );
				}
			}
			else {
				$idA = "         ";
			}
			if ( $iscommB eq " is communicating" ) {
				open( IN, "$idprocB" );
				@page = (<IN>);
				foreach (@page) {
					$idB = $_;
					chop $idB;
					( $junk, $idB ) = split( "is ", $idB );
				}
			}
			else {
				$idB = "         ";
			}

			#print "hi2\n";

		}

		if ( $AorB == 0 ) {
			$dom1 = $idA;
			$dom2 = $idB;
		}
		else {
			$dom1 = $idB;
			$dom2 = $idA;
		}

#print "time is $year $mon $mon $hour $min $sec \n";
#printf ("%s %10s | %1d%1d %7s %17s %12s %17s %12s %4d \n",$tGMT,$t1970,$card,$pair,$type,$iscommB,$dom1,$iscommA,$dom2,$current);
		open( OUT, ">>$dir/$card$pair.dat" );
		printf OUT (
			"%s %10s | %1d%1d %7s %17s %12s %17s %12s %12s %4d %6.2f %6.2f\n",
			$tGMT,    $t1970,   $card,    $pair, $type,
			$iscommB, $dom1,    $iscommA, $dom2, $serial,
			$current, $voltage, $power
		);
		close(OUT);
		if ( ( $type eq "Configb" ) && ( $current > 70 ) ) {
			print
" Configb current for pair $card$pair is too large at $current \n";
		}
		if ( ( $type eq "Iceboot" ) && ( $current > 93 ) ) {
			print
" Iceboot current for pair $card$pair is too large at $current \n";
		}
	}

}

#close ($file);
