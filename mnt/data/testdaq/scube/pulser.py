#!/usr/bin/python
# -----------------------------------------------------------------------------
# File:  pulser.py
#
# Purpose:  Automate interaction with the the S-Cube pulser.
#
# Usage: pulser.py -h
#
# Author: M. Newcomb, T. Bendfelt
#
# Date: May 2016
#
# Reference:
#   From Scube Pulser Specification, Table 3    Terminal Commands
#   ___________________________________________________________________________________________
#   |  Commands         |  Function                                  |  Parameter Range       |
#   -------------------------------------------------------------------------------------------
#   |  Global Commands                                                                        |
#   |-----------------------------------------------------------------------------------------|
#   |  START            |  Enable the global clock.                                           |
#   |-----------------------------------------------------------------------------------------|
#   |  STOP             |  Disable the global clock.                                          |
#   |-----------------------------------------------------------------------------------------|
#   |  RST*             |  Soft-reset the module.                                             |
#   |-----------------------------------------------------------------------------------------|
#   |  ECHO 1|0         |  Enable/disable the terminal echo.                                  |
#   |-----------------------------------------------------------------------------------------|
#   |  RATE n_rate      | Set the periodic muon pulse rate.          | 1 .. 2^24 - 1          |
#   |                   |      fMUON = 6.25 MHz / n_rate             |                        |
#   |-----------------------------------------------------------------------------------------|
#   |  CHAN ch          |  Select a channel.     1 .. 64                                      |
#   |-----------------------------------------------------------------------------------------|
#   |  Channel Specific Commands                                                              |
#   |-----------------------------------------------------------------------------------------|
#   |  MUON  1|0        |  Enable/disable the muon pulses.                                    |
#   |-----------------------------------------------------------------------------------------|
#   |  DELTA  n_delta   |  Set the phase offset of the muon pulses.  |  0 .. 32 x n_rate - 1  |
#   |                   |    TDELTA = n_delta x 5 ns                 |                        |
#   |-----------------------------------------------------------------------------------------|
#   |  NOISE  1|0       |  Enable/disable the noise pulses.                                   |
#   |-----------------------------------------------------------------------------------------|
#   |  LEVEL  n_level   |  Set the random noise rate.                |   0 .. 2^32 - 1        |
#   |                   |    fNOISE = n_level x 100 MHz / 2^32       |                        |
#   |-----------------------------------------------------------------------------------------|
#   |  Query Commands                                                                         |
#   |-----------------------------------------------------------------------------------------|
#   |  RATE  ?          |  Returns the value of n_rate.                                       |
#   |-----------------------------------------------------------------------------------------|
#   |  CHAN  ?          |  Returns the value of ch.                                           |
#   |-----------------------------------------------------------------------------------------|
#   |  DELTA  ?         |  Returns the value of n_delta.                                      |
#   |-----------------------------------------------------------------------------------------|
#   |  LEVEL  ?         |  Returns the value of n_level.                                      |
#   |-----------------------------------------------------------------------------------------|
#   |  CFG  ?           |  Returns the current configuration of all channels.                 |
#   -------------------------------------------------------------------------------------------
#
# -----------------------------------------------------------------------------

from __future__ import print_function
from __future__ import division
from builtins import range
from past.utils import old_div
import argparse
import sys
import telnetlib
from time import sleep
from getopt import getopt

def pulser_on(muon, noise, setdelta = False, host = "scube-lantronix",
           port  = 2009):

        #muon  = 20.0
        #noise = 500
        print("Setting pulser to %f/%f" % (muon, noise))
        tn = telnetlib.Telnet(host, port)

        iM = 6250000.0 / muon
        iN = old_div(noise * 2**32, 1E8)

        print("RATE: ", iM, " LEVEL: ", iN)

        tn.write("RATE %d\n" % iM)

        for channel in range(64):
                tn.write("CHAN %d\n" % (channel+1))
                sleep(0.1)
                tn.write("NOISE 1\n")
                tn.write("MUON 1\n")
                sleep(0.1)
                tn.write("LEVEL %d\n" % iN)
                delta = channel * 5
                sleep(0.1)
                if setdelta:
                        tn.write("DELTA %d\n" % delta)
                else:
                        tn.write("DELTA 0\n")
                sleep(0.1)

        sleep(0.5)
        print("Starting...")
        tn.write("START\n")
        sleep(5)
        tn.close()
        print("Pulser Set!")


def pulser_off(host = "scube-lantronix",
               port = 2009):

        tn = telnetlib.Telnet(host, port)

        print("Stopping...")
        tn.write("STOP\n")

        sleep(5)

        tn.close()
        print("Pulser Off")

def pulser_display(host = "scube-lantronix",
               port = 2009):

        tn = telnetlib.Telnet(host, port)

        tn.write("CFG ?\n")
        sleep(0.5)
        print(tn.read_very_eager())
        tn.close()

if __name__=="__main__":
        parser = argparse.ArgumentParser(description='Auotmates control of the SCUBE pulser')
        parser.add_argument('action', help='Action [default=display]', nargs='?', choices=['on', 'off', 'interval', 'display' ], default="display")
        parser.add_argument('-host','--host', help='Pulser host [default=scube-lantronix]', type=str, required=False, default="scube-lantronix", dest='host')
        parser.add_argument('-port','--port', help='Pulser port [default=2009]', type=int, required=False, default=2009, dest='port')
        parser.add_argument('-nr','--noise-rate', help='Noise rate', type=int, required=False, default=1500, dest='noise')
        parser.add_argument('-mr','--muon-rate', help='Muon rate', type=int, required=False, default=20, dest='muon')
        parser.add_argument('-d','--delta', help='Set a phase offset for muon pulses', type=bool, required=False, default=False, dest='delta')
        parser.add_argument('-i','--interval', help='In interval mode, run pulser for interval number of seconds [default=10]' , type=int, required=False, default=10, dest='interval')
        args = vars(parser.parse_args())

        if args['action'] == "display":
            pulser_display(args['host'], args['port'])
        elif args['action'] == "on":
            pulser_on(args['muon'], args['noise'], args['delta'], args['host'], args['port'])
        elif args['action'] == "off":
            pulser_off()
        elif args['action'] == "interval":
            pulser_on(args['muon'], args['noise'], args['delta'], args['host'], args['port'])
            print("Running pulser for", args['interval'], "seconds...")
            sleep(args['interval'])
            pulser_off(args['host'], args['port'])

        #pulser_display()
        #pulser_on(20, 2000)
        #pulser_on(20, 1500)
        #pulser_on(20, 1000)
        #pulser_on(1, 10)
        #sleep(10)
        #pulser_off()
        print("Done")
