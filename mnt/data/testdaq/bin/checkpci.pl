#!/usr/bin/perl

# checkpci.pl
# John Jacobsen, NPX Designs, Inc., jacobsen\@npxdesigns.com
# Started: Fri Jul 15 08:53:26 2005

package MY_PACKAGE;
use strict;

my $pcirbf = shift; die "Usage: $0 <pci_xxx.rbf>\n" unless defined $pcirbf;
my $pcinum;
if($pcirbf =~ /pci_(\d+).rbf/i) {
    $pcinum = $1;
    print "Looking for PCI revision $pcinum.... ";
} else {
    die "$0: PCI firmware file name '$pcirbf' not in standard format, won't check DOR cards.\n";
}

my @fvers = `/usr/local/bin/fvers.pl`;

my $foundpci = 0;
my $founddor = 0;

for(@fvers) {
    if(/PCI=(\d+)/) {
	$founddor++;
	my $pcirev = $1;
	if(/DOR=1\S*$/) {
	    $foundpci++;
	    if($pcirev != $pcinum) {
		warn @fvers;
		die <<EOF;

$0: PCI revision $pcirev does not match $pcirbf.  You should upgrade by 
installing the appropriate dor-driver-pci RPM.
EOF
;
	    }
	} elsif(/DOR=0\S*$/) {
	    # ignore
	} else {
	    warn @fvers;
	    chomp;
	    die "Unknown PCI revision [$_]!\n";
	}	    
    }
}

die "\n$0: Warning: no valid dor cards found!\n" unless $founddor;

print "OK.\n";
__END__

