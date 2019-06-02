#!/bin/bash
#Original credit: haslettj
#Edit for comments/usibility/functionality: TGYK

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
# $7 = Elevation

#Common R820T supported gain values:
#0.0 0.9 1.4 2.7 3.7 7.7 8.7 12.5 14.4 15.7 16.6 19.7 20.7 22.9 25.4
#28.0 29.7 32.8 33.8 36.4 37.2 38.6 40.2 42.1 43.4 43.9 44.5 48.0 49.6

#NOAA gain
ngain=CHANGEME
#Meteor gain
mgain=CHANGEME
#PPM value to be used by rtl_fm
ppm=CHANGEME
#Meteor raw sampling rate
meteorrate=120000
#Meteor downsampling rate
meteordownrate=120000
#NOAA raw sampling rate
noaarate=60000
#NOAA downsampling rate
noaadownrate=11025
#PLL factor for Meteor demodulation
pll=220
#R/G/B values to be used by medet
#65,65,64 creates a really nice false-color image
red=65
green=65
blue=64
#Set to TRUE to enable use of rtl_fm priority setting via nice
usenice=FALSE
#Nice value (-20 through 19) -20 is highest priority, 0 is default
nicevalue=-15
#Set to TRUE to enable use of bias tee for LNA power
biast=FALSE
#Set to TRUE to enable automatic conversion of bmp to png using imagemagick
conv=FALSE
#Set to TRUE to enable removal of raw I/Q file, wav files, and symbol files for space-saving
#This option leaves all successfully decoded images, and if successful Meteor-M 2 decoding, decoded dump files
cleanup=FALSE
#Set to TRUE to enable removal of directory and captured pass if wxtoimg gets a bad pass
prune=FALSE
#Set to TRUE to send email with captured pass/details.
sendemail=FALSE
#Email to send to
senduser=you@youremail.com
#Directory to make date/time folders for organization
wdir="/home/pi/weather/"



#Get current date/time for folder structure
date=`date +%-m-%-d-%Y`
curtime=`date +%-I:%M%^p`
correctiontime=$(date --date="@`expr $6 + $5`" +%Y%m%d%H%M.%S)


#Create file for past-the-fact reference of details for image analysis
echo "Satellite: $1" > $3.txt
echo "Frequency: $2 MHz" >> $3.txt
echo "Pass start time: $curtime" >> $3.txt
echo "Pass start epoch time: $5" >> $3.txt
echo "Pass duration: $(date --date="@$6" +"%M minutes, %S  seconds")" >> $3.txt
echo "Pass elevation: $7" >> $3.txt
if [ "${1}" == "METEOR-M 2" ]
  then
    echo "Gain used by rtl_fm: $mgain" >> $3.txt
    echo "Sample rate of raw wav file: $meteorrate" >> $3.txt
    echo "Sample rate used to downsample and process: $meteordownrate" >> $3.txt
    echo "Pll value used for QPSK demodulation: $pll" >> $3.txt
    echo "RGB values used in generation of image: R-$red G-$green B-$blue" >> $3.txt
  else
    echo "Gain used by rtl_fm: $ngain" >> $3.txt
    echo "Sample rate of raw wav file: $noaarate" >> $3.txt
    echo "Sample rate used to downsample and process: $noaadownrate" >> $3.txt
fi

#Turn on bias tee for LNA/Filter if enabled
if [ "$biast" == "TRUE" ]
  then
    /usr/local/bin/rtl_biast -b 1
fi

#If there has been other captures on this date, only make time-related folder, otherwise make date and time-related folders
if [ ! -d "$wdir$date" ]
  then
    mkdir "$wdir$date"
    mkdir "$wdir$date"/"$curtime"
elif [ ! -d "$wdir$date"/"$curtime" ]
  then
    mkdir "$wdir$date"/"$curtime"
fi

#Create backup of the current tle file, should you want to re-process data past-the-fact
if [ ! -e "$wdir$date/weather.tle" ]
  then
    cp $wdir/predict/weather.tle $wdir$date/weather.tle
fi

#Determine if capturing Meteor-M 2 or NOAA, and capture accordingly
if [ "${1}" != "METEOR-M 2" ]
  then
    #Use nice if enabled to set process priority
    if [ "$usenice" == "TRUE" ]
      then
        #Capture for $6 seconds at $2 MHz at $noaarate bandwidth with gain of $ngain in wav format FM demodulated and de-emphasis filtered, save to $3-$noaarate.wav
        sudo timeout $6 nice -n $nicevalue rtl_fm -f ${2}M -s $noaarate -g $ngain -p $ppm -E wav -E deemp -F 9 -M fm $3-$noaarate.wav
      else
        #Capture for $6 seconds at $2 MHz at $noaarate bandwidth with gain of $ngain in wav format FM demodulated and de-emphasis filtered, save to $3-$noaarate.wav
        sudo timeout $6 rtl_fm -f ${2}M -s $noaarate -g $ngain -p $ppm -E wav -E deemp -F 9 -M fm $3-$noaarate.wav
    fi
    #Turn off bias tee before converting audio if bias tee was enabled
    if [ "$biast" == "TRUE" ]
      then
        /usr/local/bin/rtl_biast -b 0
    fi
    #Use sox to downsample to $noaadownrate for wxtoimg
    sox -t wav $3-$noaarate.wav $3.wav rate $noaadownrate
    #Correct the timestamp for the pass duration so map lines up
    touch -t $correctiontime $3.wav
  else
    if [ "$usenice" == "TRUE" ]
      then
        sudo timeout $6 nice -n $nicevalue rtl_fm -f ${2}M -s $meteorrate -g $mgain -p $ppm -M raw $3-$meteorrate.raw
      else
        #Capture for $6 seconds at $2 MHz at $meteorrate bandwidth with gain of $mgain in raw IQ format, save to $3-$meteorrate.raw
        sudo timeout $6 rtl_fm -f ${2}M -s $meteorrate -g $mgain -p $ppm -M raw $3-$meteorrate.raw
    fi
    #Turn off bias tee before converting audio if bias tee was enabled
    if [ "$biast" == "TRUE" ]
      then
        /usr/local/bin/rtl_biast -b 0
    fi
    #Convert from raw IQ to wav format, and downsample to $meteordownrate
    sox -t raw -r $meteorrate -c 2 -b 16 -e s $3-$meteorrate.raw -t wav $3-$meteordownrate.wav rate $meteordownrate
    #Amplify the signal so it can be QPSK demodulated later. Use the wav from above at 98% volume to prevent dithering.
    sox -v 0.98 $3-$meteordownrate.wav $3.wav gain -n
fi

#Determine if we are processing Meteor-M 2 or NOAA.
if [ "${1}"  != "METEOR-M 2" ]
  then
    #Some maths to make the map overlay line up properly
    PassStart=`expr $5 + 90`
    #Make the overlay map from the TLE file and times
    /usr/local/bin/wxmap -T "${1}" -H $4 -p 0 -l 0 -o $PassStart ${3}-map.png
    #Detect if image decoding was "good" and make ZA enhancement image
    if ! /usr/local/bin/wxtoimg -m ${3}-map.png -e ZA $3.wav $3-ZA.png 2>&1 | grep "warning: couldn't find telemetry data\|warning: Narrow IF"
      then
        #Use wxtoimg to decode the image, use MSA-precip enhancement
        /usr/local/bin/wxtoimg -m ${3}-map.png -e MSA-precip $3.wav $3-MSA-precip.png
        #Use wxtoimg to decode the image, use MCIR enhancement
        /usr/local/bin/wxtoimg -m ${3}-map.png -e MCIR $3.wav $3-MCIR.png
        #Use wxtoimg to decode the image, use NO enhancement
        /usr/local/bin/wxtoimg -m ${3}-map.png -e NO $3.wav $3-NO.png
        #Use wxtoimg to decode the image, use HVC enhancement
        /usr/local/bin/wxtoimg -m ${3}-map.png -e HVC $3.wav $3-HVC.png

        #If enabled, send an email with the pictures attached, only on successful capture.
        if [ "$sendemail" == "TRUE" ]
          then
            #Get attachments as png files
            for attachment in *.png
              do
                #Don't send the map file
                if ! echo $attachment | grep "map"
                  then
                    #Create our attachment string
                    attstr+=" -A $attachment"
                fi
              done
            #Send the email.
            mail -s $3 $attstr $senduser < $3.txt
        fi
    else
        #If bad capture detected, state that for the record
        echo "Narrow IF band detected, or no Telemetry data found! Was there a good pass?"
        #If pruning is enabled, delete the directory and current pass
        if [ "$prune" == true ]
          then
            rm -rf $wdir$date/$curtime
            rm $3*
        fi
    fi
else
    #Use meteor_demod to QPSK demodulate the downsampled iq file into symbols. PLL rate of $pll, bandwidth of $meteordownrate
    /usr/bin/meteor_demod -B -q -b $pll -s $meteordownrate -r 72000 -o $3.s $3.wav
    #Use medet to decode the symbol files into an image. Split images into seperate channels and composite, make stat file as well.
    /usr/local/bin/medet $3.s $3 -cd -q -r $red -g $green -b $blue
    #If conversion is enabled, then convert!
    if [ "$conv" == "TRUE" ]
      then
        #Check for successful decoding first
        if [ -e $3.bmp ]
          then
            #Convert!
            convert $3.bmp $3.png
          else
            #If no successful decoding was found, state why there wasn't a conversion
            echo "No BMP generated from medet, not converting! Was there a good capture?"
        fi
    fi
    #If email sending is enabled, send an email!
    if [ "$sendmail" == "TRUE" ]
      then
        #Check for successful decoding first
        if [ -e $3.bmp ]
          then
            #Check to see if the file got converted. Only one image to send this way
            if [ "$conv" == "TRUE" ]
              then
                #Send png if conversion is enabled
                mail -s $3 -A $3.png $senduser < $3.txt
            else
                #Send bmp is conversion is not enabled
                mail -s $3 -A $3.bmp $senduser < $3.txt
            fi
        else
          #If no successful decoding was found, state why there wasn't an email sent
          echo "No BMP generated from medet, not sending mail! Was there a good capture?"
        fi
    fi

fi

#Perform cleanup if enabled
if [ "$cleanup" == "TRUE" ]
  then
    rm $3*.wav
    rm $3*.raw
    rm $3*.s
fi

#Move all files to their folders.
mv "$3"* "$wdir$date"/"$curtime"/
