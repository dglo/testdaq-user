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
# point to pdaq stuff for PATH, PYTHONPATH, CLASSPATH, also define pdaq environment variables
source ${HOME}/daq.setup
# allow use of RunConfig packages and abscal packages
export PYTHONPATH=$PYTHONPATH:$HOME/abscal/daq:$HOME/omicron-tools:$HOME/RunConfig 

export JAVA_HOME
export CLASSPATH

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
     source set_prompt_long
    ;;
  *)  : # non interactive
     # commands for non-interactive shells go here
    ;;

esac