#!/usr/bin/python

import sys
import time
import datetime

documentation = '''
A function to take two input date-time strings and calculate the time
difference between them. Format must be as in DATESTRING defined below.

Usage:
  > python py/timeDiff.py str1 str2
  where str1 and str2 are datestrings.

Example:
  > python py/timeDiff.py 16/04/21-23:57:15 16/04/22-00:12:05
'''

DATESTRING = '%y/%m/%d-%H:%M:%S'

narg = len(sys.argv)
if narg < 3:
    print documentation
    print "INSUFFICIENT NUMBER OF ARGUMENTS SUPPLIED."
    print "Exiting."
    sys.exit()

def timeconv(tt):
    return(datetime.datetime(*(time.strptime(tt,DATESTRING)[0:6])))

t1 = sys.argv[1]
t2 = sys.argv[2]

print timeconv(t2) - timeconv(t1)
