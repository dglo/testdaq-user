# If it exists, activate pDAQ's Python virtual environment
# This is temporary until the migration of most tools to the pdaq user
ENVDIR="/usr/local/pdaq/env"
if [ -d $ENVDIR -a -f $ENVDIR/bin/activate ]; then
  source $ENVDIR/bin/activate
fi

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

PATH=${HOME}/bin:${PATH}:/sbin
PATH=$PATH:$HOME/hutil:$HOME/python

# added May 20 2015 for hawc-hub machine
PATH=${PATH}:$HOME/omicron-tools
# Added for domhub-tools-python
PATH=${PATH}:$HOME/.local/bin

# point to pdaq stuff for PATH, PYTHONPATH, CLASSPATH, also define pdaq environment variables
if [ -f ${HOME}/daq.setup ]; then
    source ${HOME}/daq.setup
fi
# allow use of RunConfig packages and abscal packages
export PYTHONPATH=$PYTHONPATH:$HOME/abscal/daq:$HOME/omicron-tools:$HOME/RunConfig 

# DM-ice-specific tools
if [ -f ${HOME}/dmice-env.sh ]; then
    source ${HOME}/dmice-env.sh
fi

export JAVA_HOME
export CLASSPATH

alias ssh='ssh -X'
alias scp='scp -p'
alias cp='cp -p'
alias mmdisplay='java -Xmx300m -jar $HOME/mmdisplay.jar'
alias domdisplay='java -Xmx300m -jar $HOME/domdisplay.jar'
alias currentTester='java -Xmx300m -jar $HOME/currentTester.jar'
alias stf="echo REMEMBER: DO NOT RUN ON ALL T even or ALL U odd DOMs at THE SAME TIME;echo 0 > /proc/driver/domhub/blocking;java icecube.daq.stf.STF"
alias pow='domhub all quickstatus | dye_icl.pl'

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

case $- in
  *i*) : # interactive
     # commands for interactive shells go here
     # Set prompt
     export PS1="\[\033[0;32m\]\h \[\033[0;34m\]\u \[\033[0;29m\]\$PWD/ "
    ;;
  *)  : # non interactive
     # commands for non-interactive shells go here
    ;;

esac
