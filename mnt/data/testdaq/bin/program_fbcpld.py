#!/bin/env python
# This script burns an image on the DOM local
# filesystem into the flasherboard CPLD
from __future__ import print_function
import sys
from icecube.domtest.ibidaq import ibx

q = ibx('localhost', int(sys.argv[1]))
print(q.send('enableFB s" %s" find if fb-cpld endif .s disableFB drop' % sys.argv[2]))
