#!/usr/bin/env python

from __future__ import print_function
import sys
from time import strftime, localtime
import string

f = sys.stdin

for l in f:
    t = l.split()
    t[0] = strftime("%Y-%m-%d %H:%M:%S %Z", localtime(float(t[0])))
    print(string.join(t))
    
    
