#!/bin/bash
# Simple little script to automate the packaging+uploading of
# iDOM data.  Mainly duplicated from domcalUpload.sh. 
# IR 20140528

# Keep the trailing /, please
uploadDir="dropbox/satellite-only/high-priority/"

# Hacky, I know.  The data we want to tar+upload is in
# ./$resultsDir/$idomSubdir/*, but we want the tar file to unpack it into
# ./$idomSubdir/* so we use the -O option, which is a bit messy
resultsDir="Results"
idomSubdir="iDOM"

idomName="incDOM.`date +%Y%m%d`"

if [ -e $idomOrigDir ]
then
  if [ -e $idomName* ]
  then
    echo "Some files related to $idomName exist already, not doing anything"
  else
    tar -c -z -f $uploadDir$idomName.tar.gz -C $resultsDir $idomSubdir
    touch $uploadDir$idomName.tar.sem

    echo "Waiting for SPADE/JADE to pick up files, this can take a few minutes..."
    while [ -e $uploadDir$idomName.tar.gz -o -e $uploadDir$idomName.tar.sem ]
    do
      echo "Still waiting"
      sleep 2
    done
    echo "SPADE/JADE picked up the iDOM files, email folks to let them know!"
  fi
else
  echo "Didn't find a $idomOrigDir directory, so didn't do anything"
fi
