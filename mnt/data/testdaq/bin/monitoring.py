#!/bin/env python

import sys
from struct import unpack

def MonitorRecordFactory(buf, domid='????????????', timestamp=0L):
    domClock = 0
    for i in range(6):
        domClock = (domClock << 8) | unpack('B', buf[i+4])[0]
    (moniLen, moniType) = unpack('>hh', buf[0:4])
    if moniType == 0xC8:
        return HardwareMonitorRecord(domid, timestamp, buf, moniLen, moniType, domClock)
    elif moniType == 0xC9:
        return ConfigMonitorRecord(domid, timestamp, buf, moniLen, moniType, domClock)
    elif moniType == 0xCB:
        return ASCIIMonitorRecord(domid, timestamp, buf, moniLen, moniType, domClock)
    else:
        return MonitorRecord(domid, timestamp, buf, moniLen, moniType, domClock)
    
class MonitorRecord:
    """
    Generic monitor record type - supports the common base information
    contained in all monitor records.
    """
    def __init__(self, domid, timestamp, buf, moniLen, moniType, domClock):
        self.domid = domid
        self.timestamp = timestamp
        self.buf = buf
        self.moniLen = moniLen
        self.moniType = moniType
        self.domClock = domClock
        
    def getDOMClock(self):
        """Retrieve the DOM timestamp."""
        return self.domClock
        
class ASCIIMonitorRecord(MonitorRecord):
    """
    Implements the ASCII type logging monitor record.
    """
    def __init__(self, domid, timestamp, buf, moniLen, moniType, domClock):
        MonitorRecord.__init__(self, domid, timestamp, buf, moniLen, moniType, domClock)
        self.text = self.buf[10:]
        
    def getMessage(self):
        """Retrieve the payload message from the DOM monitor record."""
        return self.text

class ConfigMonitorRecord(MonitorRecord):
    def __init__(self, domid, timestamp, buf, moniLen, moniType, domClock):
        MonitorRecord.__init__(self, domid, timestamp, buf, moniLen, moniType, domClock)

    def __str__(self):
        print len(self.buf)
        return """
    DOM Id .............................. %s
    UT Timestamp ........................ %x
    DOM Timestamp ....................... %x
    Config Version ...................... %d
    Mainboard ID ........................ %8.8X%4.4X
    HV Control ID ....................... %8.8X%8.8X
    FPGA Build ID ....................... %d
    DOM-MB Software Build ID ............ %d
    Message Handler Version ............. %d.%2.2d
    Experiment Control Version .......... %d.%2.2d
    Slow Control Version ................ %d.%2.2d
    Data Access Version ................. %d.%2.2d
    Trigger Configuration ............... %x
    ATWD Readout Info ................... %x
    """ % (
        (self.domid, self.timestamp, self.domClock) +
        unpack('>B3xIH2xIIH2xH8B2xII', self.buf[10:])
        )
    
class HardwareMonitorRecord(MonitorRecord):
    
    def __init__(self, domid, timestamp, buf, moniLen, moniType, domClock):
        MonitorRecord.__init__(self, domid, timestamp, buf, moniLen, moniType, domClock)
        
    def getVoltageSumADC(self):
        """Gets the voltage sum ADC."""
        return unpack('h', self.buf[12:14])[0]
        
    def getPressure(self):
        """Returns the pressure in kPa."""
        padc = unpack('h', self.buf[16:18])[0]
        vsum = self.getVoltageSumADC()
        return (float(padc) / float(vsum) + 0.095) / 0.009 
        
    def __str__(self):
        return """
        DOM Id ....................... %s
        UT Timestamp ................. %x
        DOM Timestamp ................ %x
        Hardware Record Ver .......... %d
        Voltage Sum ADC .............. %d
        5 V Power Supply ............. %.3f
        Pressure ..................... %.1f
        5 V Current Monitor .......... %d
        3.3 V Current Monitor ........ %d
        2.5 V Current Monitor ........ %d
        1.8 V Current Monitor ........ %d
        -5 V Current Monitor ......... %d
        ATWD0 Trigger Bias DAC ....... %d
        ATWD0 Ramp Top DAC ........... %d
        ATWD0 Ramp Rate DAC .......... %d
        ATWD Analog Ref DAC .......... %d
        ATWD1 Trigger Bias DAC ....... %d
        ATWD1 Ramp Top DAC ........... %d
        ATWD1 Ramp Rate DAC .......... %d
        FE Bias Voltage DAC .......... %d
        Multi-PE Discriminator DAC ... %d
        SPE Discriminator DAC ........ %d
        LED Brightness DAC ........... %d
        FADC Reference DAC ........... %d
        Internal Pulser DAC .......... %d
        FE Amp Lower Clamp DAC ....... %d
        FL Ref DAC ................... %d
        MUXer Bias DAC ............... %d
        PMT HV DAC Setting ........... %d
        PMT HV Readback ADC .......... %d
        DOM Mainboard Temperature .... %.1f
        SPE Scaler ................... %d
        MPE Scaler ................... %d
        """ % (
            (self.domid, self.timestamp, self.domClock) + 
            unpack('>Bx27hii', self.buf[10:])
            )

def readMoniStream(f):
    
    xroot = { }
    
    while 1:
        hdr = f.read(32)
        if len(hdr) == 0: break
        (recl, recid, domid, timestamp) = unpack('>iiq8xq', hdr)
        domid = "%12.12X" % (domid)
        #print recl, recid, domid, timestamp
        buf = f.read(recl - 32)
        moni = MonitorRecordFactory(buf, domid, timestamp)
        if domid not in xroot: 
            xroot[domid] = [ ]
        xroot[domid].append(moni)
        
    return xroot
