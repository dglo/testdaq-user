#!/bin/env python

# This script burns an image on the DOM local
# filesystem into the flasherboard CPLD

import sys
from icecube.domtest.ibidaq import ibx

q = ibx('localhost', int(sys.argv[1]))
print q.send('enableFB getFBfw .s disableFB drop' )
