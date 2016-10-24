#!/bin/bash
# Simple little script to automate the packaging+uploading of
# DOMCal data.  Hopefully, just simple enough to get the job done.
# IR 20140526
#
# Updated 20140717 to add emailing functionality IR

if (($# != 1))
then
  echo "Expected syntax is 'domcalUpload.sh section', where section is the"
  echo "section of the detector where the DOMCal was run on, eg icetop"
  exit
fi

# Keep the trailing /, please
uploadDir="dropbox/satellite-only/high-priority/"

calSection=$1
domcalOrigDir="domcal"
domcalName="domcal-`date +%Y%m%d`-$calSection-unvetted"

SENDMAIL=/usr/sbin/sendmail
email_recipients=blaufuss@icecube.umd.edu,john.kelley@icecube.wisc.edu,tomas.j.palczewski@ua.edu,icecube@icecube.usap.gov

if [ -e $domcalOrigDir ]
then
  if [ -e $domcalName* ]
  then
    echo "Files related to $domcalName exist already, not doing anything"
  else
    mv $domcalOrigDir $domcalName
    tar cf ~/$domcalName.dat.tar $domcalName
    cp $domcalName.dat.tar $uploadDir
    echo "DOMCal data /$domcalName" > $uploadDir$domcalName.sem
    echo "Waiting for SPADE/JADE to pick up $domcalName..."
    while [ -e $uploadDir$domcalName.dat.tar -o -e $uploadDir$domcalName.sem ]
    do
      echo "Still waiting"
      sleep 10
    done
    echo "SPADE/JADE picked up the DOMCal files."
    echo "Emailing folks to let them know."
    temp_email_file=tempemailfile`date '+%Y%m%d%H%M%S'`.txt
    echo "Subject: $domcalName uploaded via SPADE" > $temp_email_file
    echo "" >> $temp_email_file
    echo "This is an automated message, email the winterovers at icecube@icecube.usap.gov with any questions" >> $temp_email_file
    cat $temp_email_file | $SENDMAIL $email_recipients
    rm $temp_email_file

  fi
else
  echo "Didn't find a $domcalOrigDir directory, so didn't do anything"
fi
