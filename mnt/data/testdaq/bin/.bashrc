BFDROOT=/usr/local/icecube/tools
#CVS_RSH=ssh
#CVSROOT=:pserver:bfd@glacier.lbl.gov:/home/icecube/cvsroot

# Set up JAVA 
# Note that the directories should be listed from best to worst
JAVA_HOME=
for j in /usr/lib/jvm/* /opt/ibm/* /usr/lib/jvm/java* /usr/java/jdk*; do
    if [ -z "$JAVA_HOME" -a -d "$j" ]; then
        if [ -d "$j/jre" -a -d "$j/jre/bin" -a -f "$j/jre/bin/java" ]; then
            JAVA_HOME="$j/jre"
        else
        if [ -d "$j/bin" -a -f "$j/bin/java" ]; then
            JAVA_HOME="$j"
        fi
    fi
fi
done
if [ -z "$JAVA_HOME" ]; then
    echo "$0: Cannot find Java directory; JAVA_HOME was not set" >&2
else
    export JAVA_HOME
    PATH=${JAVA_HOME}/bin:${PATH}
fi
alias java=${JAVA_HOME}/bin/java

PATH=${PATH}:${HOME}/bin:/sbin
PATH=${PATH}:/usr/local/icecube/tools
PATH=$PATH:$HOME/hutil:$HOME/python

source setclasspath $HOME/work

export CVS_RSH CVSROOT
export BFDROOT JAVA_HOME ANT_HOME 
export PYTHONPATH=$HOME/FAT/PyDOM

export CLASSPATH
export FAT_DB=sps-testdaq01
export FAT_HUB=`cat /usr/local/etc/.domhub_name`
export FAT_OPERATOR="krasberg\@icecube.wisc.edu,everhagen\@icecube.wisc.edu,scorby\@icecube.wisc.edu,justin.balantekin\@icecube.wisc.edu"


alias ssh='ssh -X'
alias scp='scp -p'
alias cp='cp -p'
alias mmdisplay='java -Xmx300m -jar $HOME/mmdisplay.jar'
alias domdisplay='java -Xmx300m -jar $HOME/domdisplay.jar'
alias currentTester='java -Xmx300m -jar $HOME/currentTester.jar'
alias stf="echo REMEMBER: DO NOT RUN ON ALL T even or ALL U odd DOMs at THE SAME TIME;echo 0 > /proc/driver/domhub/blocking;java icecube.daq.stf.STF"

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

case $- in
  *i*) : # interactive
     # commands for interactive shells go here
# source ~/fat.setup
 echo
 echo "for icecube software help, type 'icehelp'"
 echo
 complete -W "dor-driver pUp pDown quickstatus status-output status checkGPS inice-commissioning domcal gotoiceboot stf monitorDomhubApp checkVersions TestDAQ splitters pDAQ-interaction" icehelp
 . $HOME/bin/domhub_completions.sh
 source set_prompt_long

    ;;
  *)  : # non interactive
     # commands for non-interactive shells go here
    ;;

esac
