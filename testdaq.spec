# Be sure buildpolicy set to do nothing
%define        __spec_install_post %{nil}
%define          debug_package %{nil}
%define        __os_install_post %{_dbpath}/brp-compress

Summary: DOMHub testdaq user scripts
Name: testdaq
Version: 13.1
Release: 1
License: Copyright 2016 IceCube Collaboration
Group: System Environment/Base
SOURCE0 : %{name}-%{version}.tar.gz
URL: http://icecube.wisc.edu

# Required DBD module for Perl not autodetected
Requires: perl(DBD::mysql)
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%description
%{summary}

%prep
%setup -q

%build
# Empty section.

%install
rm -rf %{buildroot}
mkdir -p  %{buildroot}

# in builddir
cp -a * %{buildroot}

%clean
rm -rf %{buildroot}

%files
%defattr(-, testdaq, testdaq, -)
%attr(-, root, root) %dir /mnt
%attr(-, root, root) %dir /mnt/data
%attr(700, -, -) %dir /mnt/data/testdaq/.ssh
%attr(600, -, -) /mnt/data/testdaq/.ssh/id_dsa
%attr(777, -, -) %dir /mnt/data/testdaq/dropbox/tape
%attr(777, -, -) %dir /mnt/data/testdaq/dropbox/satellite-only/high-priority
/mnt/data/testdaq 

%changelog
* Wed May 4 2016 John Kelley <jkelley@icecube.wisc.edu>
- Massive cleanup; removal of all TestDAQ DAQ-related scripts, jars, etc.
* Thu Jan 14 2016 John Kelley <jkelley@icecube.wisc.edu>
- Run domhub quickstatus again if we find DOMs in configboot
* Mon Dec 7 2015 John Kelley <jkelley@icecube.wisc.edu>
- Change owner of /mnt/data to root
* Tue Sep 22 2015 John Kelley <jkelley@icecube.wisc.edu>
- Update e-mails in domcalUpload.sh
- Re-enable DOM cabling order checks in status and quickstatus
- Wait even longer in pCycle to avoid bogus counting
- Fix relative path in .bashrc
* Thu Aug 27 2015 John Kelley <jkelley@icecube.wisc.edu>
- Update nicknames with scintillators and scube
- Update .bashrc to labhub version
- Add labhub setup.daq
- Add DOM-MB-448 release image
* Thu Jul 23 2015 John Kelley <jkelley@icecube.wisc.edu>
- Add latest mmdisplay.jar
* Fri Apr 3 2015 John Kelley <jkelley@icecube.wisc.edu>
- Fix dropbox permissions
- Update WO email address
- Add latest domdisplay.jar
* Wed Oct 1 2014 John Kelley <jkelley@icecube.wisc.edu>
- Fix iceboot status reporting
- Add Ian's upload scripts
* Fri Aug 2 2013 John Kelley <jkelley@icecube.wisc.edu>
- Fix ssh perms
* Thu Mar 14 2013 John Kelley <jkelley@icecube.wisc.edu>
- Fix up bogus Perl dependencies
- Fix wrong default owner/group
* Wed Mar 06 2013 John Kelley <jkelley@icecube.wisc.edu>
- Removed old scripts, general cleanup
- Updated files used by quickstatus 
- Updated domhub and its config file
- Added iDOM files
- Updated scripts from kickstart.zip
- My own patches to bin/power and bin/upload_domcal
