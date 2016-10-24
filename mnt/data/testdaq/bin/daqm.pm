#!/usr/bin/perl
#
# DAQ Mantinance Package
#
package daqm;

#
# Coded by Victor Bittorf
#
# Icecube (UW-Madison)
#
# June, 2008
#
###########################
#  SOURCE CODE CONTROLED  #
###########################
#
#  ( SVN )
#
# http://code.icecube.wisc.edu/projects/daq/browser/projects/powerManagement/trunk/daqm.pm
#
# require exporter & declare we export
our $VERSION = 2.1;
use Carp;
require Exporter;
@ISA = qw(Exporter);

=x============================== 

 End DEBUG block

=cut

END {
	if ( defined $? && $? eq 0 ) {

		# do nothing
	} elsif ( defined $? && $? eq 7) {
		# special case, do nothign...
	}else {
		abort();
	}
}

=Export Tags
=cut

# @EXPORT is what is exported by default (i.e. if they do not request anything).
@EXPORT = qw(
  $DAQM_PATH SIGINT livesys
  $HOSTNAME $HOST
  email humantime
  getShortTime shortHubName
);

# Export O.K. is a the list of things that could be exported, if they want it.
@EXPORT_OK = qw(
  sendemail getMessages icglob
  strip trim
);
$EXPORT_TAGS{state}  = [qw(loadstate savestate %StateHash)];
$EXPORT_TAGS{config} = [qw( loadconfig loadLineConfig )];
$EXPORT_TAGS{args}   = [qw( ARGVGrep %DASH_HASH )];
$EXPORT_TAGS{error}  = [
	qw( icerr icwarn icprob icpriv parse
	  @Errors @Problems @Warnings @Private icdump )
];
$EXPORT_TAGS{verbose} = [qw( verbose $VERBOSE_LEVEL $VERBOSE )];
push( @EXPORT_OK, map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS );
use strict;

=our variables
	
	Vars that are exported...

=cut

# CONTSTANTS
my $EMAIL_TRUNK_SIZE = 150;    # max lines of email before truncating

# The DAQM_PATH!
our $DAQM_PATH = "$ENV{HOME}/daqm";
if ( not -e $DAQM_PATH ) {
	system("mkdir $DAQM_PATH");
}
our %StateHash;

# host name information: $HOST is the short version; i.e. pub1
our $HOST = '[unknown]';

# HOSTNAME is the full version; i.e. pub1.icecube.wisc.edu
our $HOSTNAME = '[unkown]';

# The packing template... (for pack & unpack)
our $PCKTMP = '(N/a*)*';

# dash-ops, any argument that is given via /-[a-zA-Z]/
our %DASH_HASH     = ();
our $VERBOSE_LEVEL = 0;                # verbose level (for the sub verbose)
our $VERBOSE       = $VERBOSE_LEVEL;

# cache to store errors..
our @Errors   = ();
our @Problems = ();
our @Warnings = ();
our @Private  = ();

# HUB LABELS
our @LETTERS = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

# the 4 prefixes; errors, warnings, and private emails.
my @FLAGS = (
	\@Problems => ':::',
	\@Errors   => '>>>',
	\@Warnings => '~~~',
	\@Private  => ';;;',
);
my %FLAGS = @FLAGS;
#####################################
#
# GENERATE HOST NAME
#
#####################################
#
# $HOST is the short version (i.e. pub1)
#
# $HOSTNAME is the full name (i.e. pub1.icecube.wisc.edu)
#
if ( $ENV{HOST} =~ /\w/ ) {
	$HOST = $ENV{HOST};
} elsif ( $ENV{HOSTNAME} =~ /\w/ ) {
	$HOST = $ENV{HOSTNAME};
} else {
	my $str = `echo \$HOSTNAME`;
	chomp $str;
	$HOST = $str if ( $str =~ /\w/ );
}
$HOSTNAME = $HOST;
if ( $HOST =~ /\./ ) {
	$HOST = $1 if $HOST =~ /(.+?)\./;
}

=icWARN

* * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
  The all important IceCube warnings & related subs
	
* * * * * * * * * * * * * * * * * * * * * * * * * * * *

=cut

# icdump - prints out all of the collected errors;
sub icdump {
	# don't print if we're in a special exit state:
	return if defined $? && $? eq 7;
	my %used = ();
	@Warnings = remdups(@Warnings);
	@Errors = remdups(@Errors);
	@Private = remdups(@Private);
	@Problems = remdups(@Problems);
	my @errs = ( @Warnings, @Errors, @Private, @Problems );
	my $len  = @errs;
	if ( not $len ) {
		print "\nNo Problems Found.\n\n";
	} else {
		print "\n";
		print $_, "\n" foreach sort { $b cmp $a } @errs;
		my $errnum = @Errors;
		$errnum = $errnum + @Problems;
		my $warnnum = @Warnings;
		my $privnum = @Private;
		print "\n";
		print "$errnum errors; " if $errnum;
		print "$warnnum warnings; " if $warnnum;
		print "$privnum special; " if $privnum;
		print"\n\n";
	}
}

# remove dupliate entires in an array.
sub remdups {
	my @arr  = @_;
	my %temp = ();
	$temp{$_} = 1 foreach (@arr);
	return keys %temp;
}

# adds a mesgage to an array and formats it propery.
# (adds it to an array and prefixs the correct symbol to it)
sub _addmesg {
	my $arr  = shift;
	my @mesg = @_;
	my $msg  = join( "", @mesg );
	return unless $msg =~ /\w/;
	$msg =~ s/[\n\r]//;
	my $str = sprintf( "$FLAGS{$arr} %-15s : %s", $HOST, $msg );
	push( @$arr, $str );
}

# adds an ERROR
sub icerr {
	_addmesg( \@Errors, @_ );
}

# report a problem; NO PAGE!?
sub icprob {
	_addmesg( \@Problems, @_ );
}

# adds a WARNING
sub icwarn {
	_addmesg( \@Warnings, @_ );
}

# add a private email warning...
sub icpriv {
	_addmesg( \@Private, @_ );
}

# extract errors / warnings from a block of text...
sub parse {
	my @caller = caller;
	my @block  = @_;
	my $filter = join( "|", values %FLAGS );
	my @stuff  = grep { /^$filter/ } map { split /\n/, $_ } @block;
	for ( 0 .. int( $#FLAGS / 2 ) ) {
		my $listi = $_ * 2;
		my $arr   = $FLAGS[$listi];
		my $i     = $_ * 2 + 1;
		my $regex = $FLAGS[$i];
		push( @$arr, grep { /^\s*$regex/ } @stuff );
	}
}

# strip out variable data from a message
sub strip {
	my $t = shift;
	$t =~ s/<.+?>/ / while $t =~ /<.+>/;
	$t =~ s/\s\s+/ / while $t =~ /\s\s+/;
	return trim($t);
}

# returns a reference to the messages collected so far.
sub getMessages() {
	return \@Errors, \@Private, \@Warnings;
}

sub trim {
	my $t = shift;
	$t =~ s/^\s+//;
	$t =~ s/\s+$//;
	return $t;
}
1;

=icfig

* * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
  Basic config functions, etc.
	
* * * * * * * * * * * * * * * * * * * * * * * * * * * *

=cut

=line config

	Not working at the moment

=cut

sub loadLineConfig {

	# do nothing right now...
	#	my $stuff  = shift;
	#	my $key    = shift;
	#	my $format = shift;
	#	my @refs   = @_;
	#
	#	$format =~ s/%s/(.+?)/ while ( $format =~ /%s/ );
	#	$format =~ s/%d/(.+?)/ while ( $format =~ /%d/ );
	#
	#
	#	if ( $stuff =~ /^\s*$key\s+(.+)$/m ) {
	#		my $line = $1;
	#		print "My line = $line\n";
	#		if ( $line =~ /$format/ ) {
	#			my @matches = ( $1, $2, $3, $4, $5, $6, $7, $8, $9, $10 );
	#			foreach ( 0 .. $#refs ) {
	#				${ $refs[$_] } = $matches[$_];
	#			}
	#		}
	#		else {
	#			croak "Inavlid config line: $line; expected format of $format";
	#		}
	#	}
	#	else {
	#		croak "Invalid config file: did not find $key.";
	#	}
}

=loadconfig STRING STRING ...
	
	extracts config data from a block of text.
	
	The first string is the block of text, the rest of
	the strings are considered "config vraiables" and a hash
	is created...
	
	ex.

(config text):
----------------------
foo = hi
bar= bye
hello=world
var= my variables here!
----------------------

call:
%hash = loadconfig($CONFIG_TEXT, 'foo', 'bar', 'hello', 'var');

then hash would be:
%hash = {
	'foo' => 'hi',
	'bar' => 'bye'
	'hello' => 'world'
	'var' => 'my varaiables here!',
}

=cut

sub loadconfig {
	my $text   = shift;
	my @stuff  = @_;
	my %config = ();
	foreach (@stuff) {
		if ( $text =~ /^\s*$_\s*=\s*(.+?)\s*$/m ) {
			$config{$_} = $1;
		} else {
			carp "$_ not in config file.";
		}
	}
	return %config;
}

=sendemail

	Sends an email, truncating it if necessary.
	(Truncates if the # of lines is > $EMAIL_TRUNK_SIZE)
	if it truncates, the full email and a shorter version of
	the email are sent (since the full email may take a while to arrive)...

=cut

sub sendemail {
	my @args = @_;
	my ( $subj, $msg, $to, $cc ) = @_;
	my @lines = split( /\n/, $msg );
	if ( @lines > $EMAIL_TRUNK_SIZE - 3 ) {

		# send email in parts!
		my $short =
		  "** TRUNCATED EMAIL **"
		  . join( "\n", @lines[ 0 .. $EMAIL_TRUNK_SIZE - 3 ] );
		sendemail_hooked( "   TRUNCATED   $subj", $short, $to, $cc );
	}
	sendemail_hooked(@args);
}

=sendemail_hooked

	Sends an email, given subject, message,
	and an array-REF of people to send it to.

=cut

sub sendemail_hooked {
	my ( $subj, $msg, $to, $cc ) = @_;
	my $to_line = join( ",", @$to );
	my $cc_line = " -c " . join( ",", @$cc ) . " " if ( defined $cc );
	open( MAIL, "|mail -s \"[!] $subj\" $to_line" );
	print MAIL $msg;
	print MAIL "\n";

	#	print MAIL "send bug reports to vbittorf\@icecube.wisc.edu\n";
	close MAIL;
}

=email 
	
	Sends an email (via sendemail), adds some
	information to the top of the email,
	and formats an interesting subject line...
	
=cut

sub email {
	my ( $subj, $msg, $to, $cc ) = @_;
	my ( $pk, $file ) = caller;
	my $caller    = $1 if $file =~ /\/([^\/]+)$/;
	my $time      = localtime;
	my $user      = getpwuid($>);
	my $subj_line = sprintf "%s:%s %-10s", $HOST, $caller, $subj;
	my $MESSAGE   =
	    "$subj_line $time\n\n" . $msg . "\n"
	  . sprintf( "%-13s %-30s\n", 'host name', $HOSTNAME )
	  . sprintf( "%-13s %-30s\n", 'user name', $user )
	  . sprintf( "%-13s %-30s\n", 'script',    $caller ) . "\n" . "\n";
	sendemail( $subj_line, $MESSAGE, $to, $cc );
}

=ARGV related stuff:
	
	takes a level & a message...
	prints the message if the current verbose level is
	greater than or equal to the given level.

	(see ARGVGrep for verbose level)
=cut

sub verbose {
	my ( $lvl, $msg ) = @_;
	$msg = $msg . "\n" unless $msg =~ /\n$/;
	print "verbose:$lvl: $msg" if ( $lvl <= $VERBOSE_LEVEL );
}

=ARGVGrep

=cut

sub ARGVGrep {
	my $ref    = shift;
	my @arr    = @$ref;
	my @newarr = ();
	foreach (@arr) {
		push( @newarr, $_ ) unless /^-/;
		$DASH_HASH{"--$1"} = 1  if (/^--([a-zA-Z\-]+)$/);
		$DASH_HASH{"--$1"} = $2 if (/^--([a-zA-Z\-]+)=(.+)$/);
		if (/^-([a-zA-Z]+)$/) {
			my @temp = split( //, $1 );
			foreach (@temp) {
				$DASH_HASH{"-$_"} = 1;
				$VERBOSE_LEVEL++ if (/^v$/);
			}
		}
	}
	if ( $DASH_HASH{'--version'} ) {
		print "$0 v$main::VERSION\n";
		print "daqm  v$VERSION\n";
		exit(0);
	}
	$VERBOSE = $VERBOSE_LEVEL;
	@$ref    = @newarr;
}

sub icglob {
	my ( $regex, $str ) = @_;
	my $re = "";
	while ( $regex =~ /\*/ ) {
		if ( $regex =~ /(.*?)\*(.*)/ ) {
			$re    = $re . $1 . '\w*';
			$regex = $2;
		}
	}
	$re = $re . $regex;
	return $str =~ /$re/;
}

# assign to $SIG{INT}
sub SIGINT {
	icerr("$0 caught kill signal! Exiting!");
	warn "$ENV{USER}\@$HOSTNAME:$0 caught signal; exiting!\n";
	exit(0);
}

sub humantime($) {
	my $seconds = shift;
	my $hrs     = int( $seconds / 3600 );
	$seconds = $seconds - $hrs * 3600;
	my $mins = int( $seconds / 60 );
	my $secs = $seconds - $mins * 60;
	return sprintf( "%2dh %02dm %02ds", $hrs, $mins, $secs );
}

sub abort() {
	use Dumpvalue;
	warn "X" x 70, "\n";
	warn "$0 has exited in error.\n";
	warn "Emailing core dump... ";
	open( MAIL,
"|mail -s \"CORE DUMP $0\" jkelley\@icecube.wisc.edu"
	);
	print MAIL "$0 : Exiting in error!\n";
	print MAIL "Here is the dump:\n";
	select MAIL;
	my $dumper = new Dumpvalue;
	print "\nDAQM:: DUMP:\n";
	print MAIL "@" x 50, "\n";
	$dumper->dumpvars('daqm');
	print MAIL "\n", "@" x 50, "\n";
	print MAIL "MAIN:: DUMP:\n";
	$dumper->dumpvars('main');
	print MAIL "\n", "@" x 50, "\n";
	close MAIL;
	warn "done.\n";
}

# loads a state -- assumes the state is from a file...
# named after the calling package!
sub loadstate {

	# not yet implemented...
}

sub savestate {

	# not yet implemented...
}

# return the time:
# in the format of:
# DAY HR:MIN
# exactly 9 characters.
sub getShortTime() {
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
	  localtime(time);
	my @days = qw(Sun Mon Tue Wed Thr Fri Sat);
	my $str = sprintf "%s %02d:%02d", $days[$wday], $hour, $min;
	return $str;
}

sub livesys {
	my ( $script, $name, $type, $str ) = @_;
	use Socket;
	use Sys::Hostname;
	socket( SOCKET, PF_INET, SOCK_DGRAM, getprotobyname("udp") )
	  or icprob("(LiveSystem) socket: $!");
	my ( $host, $port ) = ( "127.1", 6666 );
	my $ipaddr = inet_aton($host) || icprob("(LiveSystem) Can't get packed IP");
	my $portaddr = sockaddr_in( $port, $ipaddr );

   #my $msg           = "perly(pressure:int) [2008-03-19 22:01:41.609518] 42\n";
	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
	  localtime(time);
	my $stamp = sprintf(
		"%d-%02d-%02d %02d:%02d:%02d.000000",
		$year + 1900,
		$mon, $mday, $hour, $min, $sec
	);
	my $msg =
	  sprintf( "%s(%s:%s) 2 [%s] %s\n", $script, $name, $type, $stamp, $str );
	print "IceCube LiveSystem: sending message:\n$msg";
	my $sent = send( SOCKET, $msg, 0, $portaddr ) == length($msg);
	icprob("(LiveSystem) cannot send to $host: $!") unless $sent;
	return $sent;
}

# # # # #
#
#         DOM HUBS
#
# # # # #


# shortHubName
# converts a string that contains the name of a hub
# into a 2 character name for that hub.
sub shortHubName {
	my $name = shift;
	# special case hubs
	return "AM" if ($name =~ /amanda/i);
	return "SC" if ($name =~ /scube/i);
	return "W2" if ($name =~ /WCZAR2/i);
	return "W1" if ($name =~ /WCZAR/i);
	
	# ice top hubs
	if ($name =~ /ithub(\d+)/i) {
		return "T" . ($1 + 0) if ($1 < 10);
		return "T" . $LETTERS[$1 - 10];
	}
	
	# do the "lehubs"
	if ($name =~ /lehub(\d+)/i) {
		return "L" . ($1 + 0) if ($1 < 10);
		return "L" . $LETTERS[$1 - 10];
	}
	
	# Otherwise, default to just the hub number...
	if ($name =~ /hub(\d+)/i) {
		return sprintf "%02d", $1;
	}
	
	# if our string does not match any of the above... 
	# then we're in trouble!
	return "UN";
}
