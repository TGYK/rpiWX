#!/bin/bash
#V 1.4
#Original credit: haslettj
#Edit for comments/usibility/functionality: TGYK

#Root directory where the scripts live. The other two shell scripts will be blah/weather
#Root directory of project. This is used to detect if you are using the default git clone directory (recommended to get notification of updates)
rdir="/home/pi/rpiWX"
#Weather directory (Where the script files live if you're not using the default git clone directory)
wdir="/home/pi/rpiWX/weather"

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
#git stash
#echo "Configs stashed!"
#git pull origin master
#echo "Update downloaded!"
#git stash pop
#echo "Configs restored!"


# Update Satellite Information

wget -qr https://www.celestrak.com/NORAD/elements/weather.txt -O $wdir/predict/weather.txt
grep "NOAA 15" $wdir/predict/weather.txt -A 2 > $wdir/predict/weather.tle
grep "NOAA 18" $wdir/predict/weather.txt -A 2 >> $wdir/predict/weather.tle
grep "NOAA 19" $wdir/predict/weather.txt -A 2 >> $wdir/predict/weather.tle
grep "METEOR-M 2" $wdir/predict/weather.txt -A 2 >> $wdir/predict/weather.tle



#Remove all currently scheduled at jobs (Could probably do this more cleverly so as to not interfere with other uses of at that may not be related to the satellite passes)

for i in `atq | awk '{print $1}'`;do atrm $i;done


#Schedule satellite passes with their frequencies, in order of priority:

$wdir/predict/schedule_satellite.sh "METEOR-M 2" 137.9000
$wdir/predict/schedule_satellite.sh "NOAA 19" 137.1000
$wdir/predict/schedule_satellite.sh "NOAA 18" 137.9125
$wdir/predict/schedule_satellite.sh "NOAA 15" 137.6200
