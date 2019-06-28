#!/bin/bash
#V 1.8
#Original credit: haslettj
#Edit for comments/usibility/functionality: TGYK

#Get source directory for this script
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#Run config script, use values for this script
. $srcdir/config


#Check for newer updates
if [ -d $rdir/.git ]
  then
    if ! git status -uno | grep "up-to-date"
      then
        echo "There are updates available from the github repo!"
        echo "Check the schedule_all script for instructions to update."
    fi
fi

#Instructions to update and keep configs:
#Uncomment the following line and run this script manually:

#cd $rdir
#git pull origin master
#echo "Update downloaded!"


# Update Satellite Information

wget -qr https://www.celestrak.com/NORAD/elements/weather.txt -O $sdir/weather.txt
grep "NOAA 15" $sdir/weather.txt -A 2 > $sdir/weather.tle
grep "NOAA 18" $sdir/weather.txt -A 2 >> $sdir/weather.tle
grep "NOAA 19" $sdir/weather.txt -A 2 >> $sdir/weather.tle
grep "METEOR-M 2" $sdir/weather.txt -A 2 >> $sdir/weather.tle
grep "METEOR-M2 2" $sdir/weather.txt -A 2 >> $sdir/weather.tle




#Remove all currently scheduled at jobs (Could probably do this more cleverly so as to not interfere with other uses of at that may not be related to the satellite passes)

for i in `atq | awk '{print $1}'`;do atrm $i;done


#Schedule satellite passes with their frequencies, in order of priority:

$sdir/schedule_satellite.sh "METEOR-M2 2" 137.1000 "LRPT"
$sdir/schedule_satellite.sh "METEOR-M 2" 137.1000 "LRPT"
$sdir/schedule_satellite.sh "NOAA 19" 137.1000 "APT"
$sdir/schedule_satellite.sh "NOAA 18" 137.9125 "APT"
$sdir/schedule_satellite.sh "NOAA 15" 137.6200 "APT"
