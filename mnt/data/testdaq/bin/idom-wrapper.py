#!/usr/bin/env python
#
# idom-wrapper.py
#
# Wrapper script for iDOM.pl which reads out all inclinometer
# DOMs on a given string.
#
#----------------------------------------------------------------
from __future__ import print_function

import sys
import os
import re
import subprocess
import time

#----------------------------------------------------------------
# Map of card / pair / dom locations of deployed iDOMs given
# the DOMHub hostname
idomMap = {'ichub01' : ["71B", "71A"],
           'ichub07' : ["71B", "71A"],
           'ichub08' : ["50A", "60A", "63A"],
           'ichub09' : ["70B", "70A", "71B", "71A"],
           'ichub22' : ["71B", "71A"],
           'ichub23' : ["51A", "62B", "63A", "71A"],
           'ichub24' : ["70B", "70A", "71B", "71A"],
           'ichub25' : ["31B", "53A", "62A", "71A"],
           'ichub31' : ["71B", "71A"],
           'ichub32' : ["41A", "53B", "61A", "71A"],
           'ichub35' : ["70B", "70A", "71B", "71A"],
           'ichub43' : ["41B", "52A", "61B", "71A"],
           'ichub51' : ["43B", "60B", "63B", "71A"],
           'ichub80' : ["70B", "70A", "71B", "71A"]}

# Script to read out an iDOM -- the DOM must already be in iceboot
idomCmd = "/mnt/data/testdaq/bin/iDOM.pl"

# Number of inclinometer readouts per DOM
nReadout = 4

# Wait time between readouts, in seconds
waitTime = 10

#----------------------------------------------------------------

# Does the iDOM script exist?
if not os.path.exists(idomCmd):
    print("ERROR: coudldn't find",idomCmd)
    sys.exit(-1)
    
# Check what machine we're on
cmd = ["hostname", "-s"]
p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
stdout,stderr = p.communicate()
hostname = stdout[0:-1].decode('utf8')
# Remove any sps- prefix
hostname = hostname.replace('sps-', '')

if hostname not in idomMap:
    print("No iDOMs on",hostname,",exiting.")
    sys.exit(0)

idoms = idomMap[hostname]
print("DOMHub",hostname,"has",len(idoms),"iDOMs: ",idoms)

# Loop over the iDOMs
for cwd in idoms:
    # Check that we're in iceboot
    stateCmd = "/usr/local/bin/domstate"
    if not os.path.exists(stateCmd):
        print("ERROR: coudldn't find",stateCmd)
        sys.exit(-1)
        
    cmd = [stateCmd,cwd]
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout,stderr = p.communicate()
    
    state = stdout
    m = re.match("%s iceboot" % (cwd), state)
    if not m:
        print("ERROR:",hostname,cwd,"is not in iceboot (",state[0:-1],"), skipping!")
        continue

    for i in range(nReadout):
        # Execute iDOM.pl, which actually does all the work
        cwd_long = cwd[0]+" "+cwd[1]+" "+cwd[2]
        print("Running",idomCmd,cwd_long,"...")
        cmd = idomCmd+" "+cwd_long
        p = subprocess.call(cmd, shell=True)
        # Wait a bit
        time.sleep(waitTime)
