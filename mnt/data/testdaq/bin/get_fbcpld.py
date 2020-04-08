#!/usr/bin/env python
# Get the flasherboard firmware version

from __future__ import print_function
import sys
from icecube.domtest.ibidaq import ibx

q = ibx('localhost', int(sys.argv[1]))
print(q.send('enableFB getFBfw .s disableFB drop' ))
