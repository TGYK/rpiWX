#!/bin/bash
#V 1.8
#Original credit: haslettj
#Edit for comments/usibility/functionality: TGYK

#Get source directory of this script
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#Run the config script, use values for this script
. $srcdir/config

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
# $7 = Elevation
# $8 = Transmission Mode

##TODO##
# Debug rtl_fm capture dropouts
# Callback command?
# wxproj projection postprocessing script?
# Use list of enhancements to email instead of hard-coded values
# Support uploading to imgur/similar site and send link instead?
# In overlap of pass scheduling, prefer higher elevation insstead of order priority?

#Get current date/time for folder structure
yr=`date +%Y`
mo=`date +%-m`
day=`date +%-d`

curtime=`date +%-I-%M%^p`

#Create file for past-the-fact reference of details for image analysis
echo "Satellite: $1" > $3.txt
echo "Frequency: $2 MHz" >> $3.txt
echo "Pass start time: $curtime" >> $3.txt
echo "Pass start epoch time: $5" >> $3.txt
echo "Pass duration: $(date --date="@$6" +"%M minutes, %S  seconds")" >> $3.txt
echo "Pass elevation: $7" >> $3.txt
if [ "${1}" == "METEOR-M 2" ] || [ "${1}" == "METEOR-M2 2" ]
  then
    echo "Gain used by rtl_fm: $mgain" >> $3.txt
    echo "Sample rate of raw wav file: $lrptrate" >> $3.txt
    echo "Sample rate used to downsample and process: $lrptdownrate" >> $3.txt
    if [ "${1}" == "METEOR-M 2" ]
      then
        echo "Pll value used for QPSK demodulation: $pll" >> $3.txt
        echo "RGB values used in generation of image: R-$red G-$green B-$blue" >> $3.txt
    else
        echo "Pll value used for QPSK demodulation: $pll2" >> $3.txt
        echo "RGB values used in generation of image: R-$red2 G-$green2 B-$blue2" >> $3.txt
    fi
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
if [ ! -d "$wdir$yr" ]
  then
    mkdir "$wdir$yr"
    mkdir "$wdir$yr"/"$mo"/
    mkdir "$wdir$yr"/"$mo"/"$day"
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"/"$curtime"
elif [ ! -d "$wdir$yr"/"$mo" ]
  then
    mkdir "$wdir$yr"/"$mo"/
    mkdir "$wdir$yr"/"$mo"/"$day"
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"/"$curtime"
elif [ ! -d "$wdir$yr"/"$mo"/"$day" ]
  then
    mkdir "$wdir$yr"/"$mo"/"$day"
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"/"$curtime"
elif [ ! -d "$wdir$yr"/"$mo"/"$day"/"${1}" ]
  then
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"/"$curtime"
elif [ ! -d "$wdir$yr"/"$mo"/"$day"/"${1}"/"$curtime" ]
  then
    mkdir "$wdir$yr"/"$mo"/"$day"/"${1}"/"$curtime"
fi

#Create backup of the current tle file, should you want to re-process data past-the-fact
if [ ! -e "$wdir$yr/$mo/$day/weather.tle" ]
  then
    cp $wdir/predict/weather.tle $wdir$yr/$mo/$day/weather.tle
fi

#Determine if capturing Meteor-M 2 or NOAA, and capture accordingly
if [ "${8}" == "APT" ]
  then
    #Use nice if enabled to set process priority
    if [ "$usenice" == "TRUE" ]
      then
        #Capture for $6 seconds at $2 MHz at $noaarate bandwidth with gain of $ngain in wav format FM demodulated and de-emphasis filtered, save to $3-$noaarate.wav
        timeout $6 nice -n $nicevalue /usr/local/bin/rtl_fm -f ${2}M -s $noaarate -g $ngain -p $ppm -E wav -E deemp -F 9 -M fm $3-$noaarate.wav
      else
        #Capture for $6 seconds at $2 MHz at $noaarate bandwidth with gain of $ngain in wav format FM demodulated and de-emphasis filtered, save to $3-$noaarate.wav
        timeout $6 /usr/local/bin/rtl_fm -f ${2}M -s $noaarate -g $ngain -p $ppm -E wav -E deemp -F 9 -M fm $3-$noaarate.wav
    fi
    #Turn off bias tee before converting audio if bias tee was enabled
    if [ "$biast" == "TRUE" ]
      then
        /usr/local/bin/rtl_biast -b 0
    fi
    #Use sox to downsample to $noaadownrate for wxtoimg
    sox -t wav $3-$noaarate.wav $3.wav rate $noaadownrate
    #Correct the timestamp for the pass duration so map lines up
    touch -r $3-$noaarate.wav $3.wav
  elif [ "${8}" == "LRPT" ]
    then
      #Use nice if enabled to set process priority
      if [ "$usenice" == "TRUE" ]
        then
          #Capture for $6 seconds, using nice value $nicevalue to run rtl_fm at $2 MHz at $lrptrate bandwidth with gain of $mgain in raw IQ format, pipe to sox for wav conversion and downsample, save to $3-$lrptdownrate.wav
          timeout $6 nice -n $nicevalue /usr/local/bin/rtl_fm -f ${2}M -s $lrptrate -g $mgain -p $ppm -F 9 -M raw | sox -t raw -r $lrptrate -c 2 -b 16 -e s - -t wav $3-$lrptdownrate.wav rate $lrptdownrate
        else
          #Capture for $6 seconds at $2 MHz at $lrptrate bandwidth with gain of $mgain in raw IQ format, pipe to sox for wav conversion and downsample, save to $3-$lrptdownrate.wav
          timeout $6 /usr/local/bin/rtl_fm -f ${2}M -s $lrptrate -g $mgain -p $ppm -F 9 -M raw | sox -t raw -r $lrptrate -c 2 -b 16 -e s - -t wav $3-$lrptdownrate.wav rate $lrptdownrate
      fi
      #Turn off bias tee before converting audio if bias tee was enabled
      if [ "$biast" == "TRUE" ]
        then
          /usr/local/bin/rtl_biast -b 0
      fi
      #Amplify the signal so it can be (O)QPSK demodulated later. Use the wav from above and apply normalization to -0.1 Db
      sox --norm=-0.1 $3-$lrptdownrate.wav $3.wav
  else
    echo "Unrecognized capture format! Not capturing."
fi

#Determine if we are processing APT or LRPT.
if [ "${8}"  == "APT" ]
  then
    #Some maths to make the map overlay line up properly
    PassStart=`expr $5 + 90`
    #Make the overlay map from the TLE file and times
    /usr/local/bin/wxmap -T "${1}" -H $4 -M 1 -p 0 -l 0 -o $PassStart ${3}-map.png
    #Detect if image decoding was "good" and make ZA enhancement image
    if ! /usr/local/bin/wxtoimg -m ${3}-map.png -e ZA $3.wav $3-ZA.png 2>&1 | grep "warning: couldn't find telemetry data\|warning: Narrow IF"
      then
        #Remove the ZA enhancement image
        rm $3-ZA.png
        #If cropping is enabled, run wxtoimg with -c option
        if [ "$crop" == "TRUE" ]
          then
            #Loop through the array of enhancements, using wxtoimg to make each one, with cropping enabled
            for enh in ${enhancements[@]}
              do
                #Use wxtoimg to decode the image, using list of enhancements
                wxinfo=$(/usr/local/bin/wxtoimg -c -m ${3}-map.png -e $enh $3.wav $3-$enh.png 2>&1)
                echo $wxinfo
                if echo $wxinfo | grep "wxtoimg: warning: enhancement ignored:"
                  then
                   echo "Ehnancement not available for this pass. Sensors not available at this time."
                   echo "Removing $3-$enh.png"
                   rm $3-$enh.png
                fi
            done
          else
            #Loop through the array of enhancements, using wxtoimg to make each one
            for enh in ${enhancements[@]}
              do
                #Use wxtoimg to decode the image, using list of enhancements
                wxinfo=$(/usr/local/bin/wxtoimg -m ${3}-map.png -e $enh $3.wav $3-$enh.png 2>&1)
                echo $wxinfo
                if echo $wxinfo | grep "wxtoimg: warning: enhancement ignored:"
                  then
                   echo "Ehnancement not available for this pass. Sensors not available at this time."
                   echo "Removing $3-$enh.png"
                   rm $3-$enh.png
                fi
            done
        fi
        #If enabled, send an email with the pictures attached, only on successful capture
        if [ "$sendemail" == "TRUE" ]
          then
            #Send the email, only send 2 interesting imgages due to email filesize limits
            mail -s $3 -A $3-MCIR.png -A $3-MSA.png $senduser < $3.txt
        fi
    else
        #If bad capture detected, state that for the record
        echo "Narrow IF band detected, or no Telemetry data found! Was there a good pass?"
        #If pruning is enabled, delete the directory and current pass, but only if cleanup is enabled
        if [ "$prune" == "TRUE" ] && [ "$cleanup" == "TRUE" ]
          then
            rm -rf $wdir$yr/$mo/$day/${1}/$curtime
            rm $3*
        fi
    fi
elif [ "${8}"  == "LRPT" ]
  then
    if [ "$1" == "METEOR-M 2" ]
      then
        #Use meteor_demod to demodulate the downsampled iq file into symbols. PLL rate of $pll, bandwidth of $lrptdownrate
        /usr/bin/meteor_demod -B -q -b $pll -s $lrptdownrate -m qpsk -r $symrate -o $3.s $3.wav
        #Use meteor_decode to decode the symbol files into an image.
        /usr/bin/meteor_decode -q -a $red,$green,$blue -o $3.png $3.s
      else
        #Use meteor_demod to demodulate the downsampled iq file into symbols. PLL rate of $pll, bandwidth of $lrptdownrate
        /usr/bin/meteor_demod -B -q -b $pll2 -s $lrptdownrate -m oqpsk -r $symrate2 -o $3.s $3.wav
        #Use meteor_decode to decode the symbol files into an image.
        /usr/bin/meteor_decode -d -q -a $red2,$green2,$blue2 -o $3.png $3.s
    fi

    #Verify we got a good pass
    if [ -s $3.png ]
      then
        #If smoothing is enabled, then use the script to do so!
        if [ "$rectify" == "TRUE" ]
          then
            python3 $sdir/rectify.py $3.png
        fi
        #If email sending is enabled, send an email!
        if [ "$sendemail" == "TRUE" ]
          then
            #Check to see if the file got converted/smoothed. Only one image to send this way
            if [ -e $3-rectified.png ]
              then
                #Send rectified png if conversion is enabled and rectification is enabled
                mail -s $3 -A $3-rectified.png $senduser < $3.txt
              else
                #Send png if conversion is enabled
                mail -s $3 -A $3.png $senduser < $3.txt
            fi
        fi
    #If no image is detected, we have a bad pass!
    else
      echo "There was no image produced by meteor_decode! Was there a good capture of ${1}?"
      #If pruning is enabled, let's delete some empty directories and useless files, but only if cleanup is enabled!
      if [ "$prune" == TRUE ] && [  "$cleanup" == "TRUE" ]
        then
          echo "Pruning directory and files from bad capture..."
          rm -rf $wdir$yr/$mo/$day/${1}/$curtime
          rm $3*
      fi
    fi
  else
    echo "Unrecognized processing format! Not processsing!"
fi

#Perform cleanup if enabled
if [ "$cleanup" == "TRUE" ] && [ "${3}" != "" ]
  then
    #Check if .s files exist and name begins with $3
    if ls $3*.s 1> /dev/null 2>&1
      then
        #Remove the files!
        rm $3*.s
    fi
    #Check if .wav files exist and name begins with $3
    if ls $3*.wav 1> /dev/null 2>&1
      then
        #Remove the files!
        rm $3*.wav
    fi
fi

#Move all files to their folders, if they weren't cleaned via prune/cleanup
if ls $3* 1> /dev/null 2>&1
  then
    mv "$3"* "$wdir$yr"/"$mo"/"$day"/"${1}"/"$curtime"/
fi
fi
