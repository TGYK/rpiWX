#!/bin/bash
#Original credit: haslettj
#Edit for comments/usibility/functionality: TGYK




# Update Satellite Information

wget -qr https://www.celestrak.com/NORAD/elements/weather.txt -O /home/pi/weather/predict/weather.txt
grep "NOAA 15" /home/pi/weather/predict/weather.txt -A 2 > /home/pi/weather/predict/weather.tle
grep "NOAA 18" /home/pi/weather/predict/weather.txt -A 2 >> /home/pi/weather/predict/weather.tle
grep "NOAA 19" /home/pi/weather/predict/weather.txt -A 2 >> /home/pi/weather/predict/weather.tle
grep "METEOR-M 2" /home/pi/weather/predict/weather.txt -A 2 >> /home/pi/weather/predict/weather.tle



#Remove all currently scheduled at jobs (Could probably do this more cleverly so as to not interfere with other uses of at that may not be related to the satellite passes)

for i in `atq | awk '{print $1}'`;do atrm $i;done


#Schedule satellite passes with their frequencies, in order of priority:

/home/pi/weather/predict/schedule_satellite.sh "METEOR-M 2" 137.9000
/home/pi/weather/predict/schedule_satellite.sh "NOAA 19" 137.1000
/home/pi/weather/predict/schedule_satellite.sh "NOAA 18" 137.9125
/home/pi/weather/predict/schedule_satellite.sh "NOAA 15" 137.6200