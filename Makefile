
REL=$(shell cat rel.num)
SRT=testdaq-$(REL)
STB=$(SRT).tar.gz

RPMDIR=~/rpmbuild
#ARCH=$(shell arch)
ARCH=noarch
RPM=$(RPMDIR)/RPMS/$(ARCH)/$(SRT)-1.$(ARCH).rpm

SPEC=testdaq-$(REL).spec
SUBDIRS=mnt

# Version control directories to exclude
VCS=.svn

all: rpm

# Make tarball of all non-source-controlled directories
tarball: 
	tar cvf testdaq-misc-$(REL).tar --exclude=.svn \
	 --exclude="mnt/data/testdaq/bin" --exclude="mnt/data/testdaq/*hubConfig*" \
	 --exclude="mnt/data/testdaq/scube" --exclude="mnt/data/testdaq/.bashrc"\
	 --exclude="mnt/data/testdaq/nicknames.txt" --exclude="mnt/data/testdaq/DEFAULT*"\
	 --exclude="mnt/data/testdaq/crontab.testdaq01" --exclude="mnt/data/testdaq/daq.setup"\
	 --exclude="mnt/data/testdaq/daqm"\
	 mnt/data/testdaq/* mnt/data/testdaq/.ssh mnt/data/testdaq/.stfprops
	gzip testdaq-misc-$(REL).tar

rhdirs:
	mkdir -p $(RPMDIR)
	for dir in SPECS SOURCES BUILD RPMS SRPMS ; do \
		mkdir -p $(RPMDIR)/$$dir; \
	done

rpm: $(RPM)

stb: $(STB)

spec: $(SPEC)

$(SPEC): rhdirs testdaq.spec
		@sed 's/Version: [.0-9]*/Version: $(REL)/' testdaq.spec > $(RPMDIR)/SPECS/$(SPEC)

$(STB):
		@mkdir $(SRT)
		@tar cf - $(SUBDIRS) --exclude=$(VCS) | ( cd $(SRT); tar xf - )
		@tar cf - $(SRT) | gzip -c > $(STB)
		@rm -rf $(SRT)

$(RPM): $(STB) $(SPEC) 
		@cp $(STB) $(RPMDIR)/SOURCES
		(cd $(RPMDIR)/SPECS; rpmbuild -ba $(SPEC))
