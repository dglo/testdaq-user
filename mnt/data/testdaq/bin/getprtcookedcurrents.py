#!/usr/bin/env python
#
#
# simple program to test some aspects of the DOM with the high voltage OFF
#
#
# the master data base file is kept at
#  http://icecube.wisc.edu/~krasberg/domhubinstall/domnames.dat
#
# Mark Krasberg, 2004
#
#
import icecube.domtest.ibidaq as daq
import os
import sys
import time
import socket
from getopt import getopt
import string
id=[6000]
name=[6000]
comment=[6000]


#host = sys.argv[1]
#port = int(sys.argv[2])

# Connect to the DOM
#card = args.pop(0)
#pair = args.pop(0)

domnames = 0
if os.path.isfile("/mnt/data/testdaq/python/domnames.dat"): 
  f=open('/mnt/data/testdaq/python/domnames.dat', 'r')
  domnames = 0
  line = f.readline()
  while line:
    domnames = domnames + 1
    (j,i,n,c) = line.split("|")
    id.append(string.strip(i))
    name.append(string.strip(n))
    comment.append(string.strip(c))
#    print "%12s   %-30.30s   %-30.30s" % (id[domnames],name[domnames],comment[domnames])
    line = f.readline()
  f.close()

version = 1.0
def usage():
    return """
test.py version %s
usage :: test.py <card> <pair> <domA/B 0/1>
 examples:
             test.py 2 1 b   examines card 2, wire pair 1, dom B
             test.py 2 1 0   examines card 2, wire pair 1, dom A
             test.py 1 1     examines card 1, wire pair 1, domA assumed
             test.py 1       examines card 1, wire pair 0 and domA assumed

""" % (version)


if (len(sys.argv) < 2):
    print usage()
    sys.exit(1)

opts, args = getopt(sys.argv[1:], 'v:l:h:s:')
for o, a in opts:
        if o == '-v':
                hv = int(a)
        elif o == '-l':
                disc_low = int(a)
        elif o == '-h':
                disc_high = int(a)
        elif o == '-s':
                disc_step = int(a)

card = -1
pair = -1
domAB = -1
c =0
for arg in args:
        c = c + 1
        if (c == 1) : card = int(arg)
        if (c == 2) : pair = int(arg)
        if (c == 3) :
              if (arg == 'A') : domAB = 0
              if (arg == 'B') : domAB = 1
              if (arg == 'a') : domAB = 0
              if (arg == 'b') : domAB = 1
              if (domAB == -1) : domAB = int(arg)

if (card == -1) : card = 0
if (pair == -1) : pair = 0
if (domAB == -1) : domAB = 0


#card = sys.argv[1]
#pair = int(sys.argv[2])
                                                                                
port = 5000+(int(card)*8)+(int(pair)*2) + int(domAB)
if (domAB == 0):
  port = port + 2
 
print " "
print "card = %d  pair = %d  domAB = %d   port is %d" % (card,pair,domAB,port)
print " "

q = daq.ibx("localhost", port)
date = str(int(time.time()))
#fnam = "flare-" + q.getId() + "-" + date + ".dat"
#flog = file(fnam, 'w')

#q.setDAC(10, 260)
#q.pulserAmp(amp) ???

#q.enableHV()
#q.setHV(3000)



# Set the MUXer to LED
#q.mux('ledmux')

# disc0    = 450
# disc1    = 950
# scan = q.discriminatorScan(disc0, disc1)


print " "

domid = q.getId()
domname = ""
for c in range(1,domnames):
  if domid == id[c] : 
        domname = name[c]
	domcomment = comment[c]


#print "domid = ",domid
#domname = ""
#if domid == '00013c63ba24': domname = "SPIKEY"
#if domid == '00013c6286c1': domname = "BUBBLE"
#if domid == '00013c627f13': domname = "FRANKENDOM"
#if domid == '00013c627dac': domname = "CHIP"
#if domid == '00013c62a821': domname = "SCARFACE"
#if domid == '00173d4d442a': domname = "ONE OF THREE"
#if domid == '00013c6284e6': domname = "OLD REV2 BOARD"
#if domid == '00173d4d3291': domname = "WILL WORK IN 15 MINUTES"
#if domid == '00173d4d37b6': domname = "XENON FLASHLAMP DOM"
#if domid == '00173d4d377c': domname = "V3 008 MARKDOM"
#if domid == '00173d4d3779': domname = "it disappeared - PSU? Bartol?"
#if domid == '00173d4d442c': domname = "WAHLDOM"
#if domid == '00133e0d6569': domname = "CAMEL"
#if domid == '33c5ea037bf4': domname = "V4 28057 CAMEL"

if domname == '': print "domid= ",domid,"   This DOM has no name"
else: 
   print "domid= ",domid,"    This DOM is called ",domname

print " "
t = q.readTemperature()
if t > 32767:
     t -= 65536
#print "temperature = ",t/256.0," degrees centigrade"
temperature=t/256.0

#print " "
#p = q.send('readPressure .')

hub = socket.gethostname()
domTU = "T"
if (domAB == 1) : domTU = "U"
hub = hub[-1]
location = "%s%d%d%s" % (hub,card,pair,domTU)


currents = q.send('prtCookedCurrents .')

print "prtCookedCurrents = ",currents

flog=open('/mnt/data/testdaq/Results/prtCookedCurrents/prtCookedCurrents.dat', 'a')
flog.write("%23s %-13.13s %4s %-20.20s %12s %.2f %-80.80s \n" % (time.strftime("%F %T %Z"), time.time(), location, domname,domid,temperature,currents))

#while 1:
#    r = q.spef()
#    flog.write("%d %.2f\n" % (time.time(), r))
#    flog.flush()
#    time.sleep(5.0)

q.setHV(0)
q.disableHV()

print " "
