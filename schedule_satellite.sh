#!/bin/bash
#Original credit: haslettj
#Edit for comments/usibility/functionality: TGYK


# $1 = Satellite name
# $2 = frequency

#Desired elevation to target
deselev=20

#Get prediction start/end from TLE files respectively
PREDICTION_START=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" | head -1`
PREDICTION_END=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" | tail -1`

#Get end time in epoch format
var2=`echo $PREDICTION_END | cut -d " " -f 1`

#Get maximum elevation from tle file, if elevation is positive
MAXELEV=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`

#While current y/m/d is equal to the prediction-end y/m/d, do...
while [ `date --date="TZ=\"UTC\" @${var2}" +%D` == `date +%D` ]; do
  #Get start date and time in standard format
  START_TIME=`echo $PREDICTION_START | cut -d " " -f 3-4`
  #Get start time in epoch format
  var1=`echo $PREDICTION_START | cut -d " " -f 1`
  #Get start seconds
  var3=`echo $START_TIME | cut -d " " -f 2 | cut -d ":" -f 3`
  #Build timer from end-epoch-time minus start-epoch-time plus start-seconds
  TIMER=`expr $var2 - $var1 + $var3`
  #Get date string of YMD-HMS for naming in calling receive_and_process_satellite.sh
  OUTDATE=`date --date="TZ=\"UTC\" $START_TIME" +%Y%m%d-%H%M%S`
  #If max elevation is greater than $deselev degrees, then...
  if [ $MAXELEV -gt $deselev ]
    then
      #Set allow to true
      allow="TRUE"
      #For every scheduled at job, get the time in var4
      for var4 in $(atq | sed -e 's/\t/ /g' | cut -d " " -f 1)
        do
          #Get epoch start time for job # from var4 using the scheduled job in the at command and some formatting magic
          var5=$(at -c $var4 | grep "/home/pi/weather/predict/receive_and_process_satellite.sh" | cut -d " " -f 7)
          #Get epoch pass duration for job # from var4 using the scheduled job in the at command and some formatting magic
          var6=$(at -c $var4 | grep "/home/pi/weather/predict/receive_and_process_satellite.sh" | cut -d " " -f 8)
          #Get the difference in time between scheduled at job and proposed at job
          diff=`expr $var5 - $var1`
          #Debugging output
#          echo "Pass duration for job $var4 : $var6"
#          echo "Time for job $var4 : $var5"
#          echo "Time for proposed job : $var1"
#          echo "Difference in times : ${diff#-}"
            #If the absolute value of the difference in time is less than the pass time of the read already-scheduled job, then...
            if [ ${diff#-} -lt $var6 ]
              then
                #Set allow to false
                allow="FALSE"
                #Print explaination of disallowance for scheduling
                echo "++++"
                echo "Warning: Job for $1 disallowed to be scheduled due to overlap in pass time"
                echo "Warning: Proposed start time : $(date --date="@$var1" +"%H:%M:%S")"
                echo "Warning: Conflicting job already scheduled : $(date --date="@$var5" +"%H:%M:%S")"
            fi
      done
    #If the difference has always been greater than the pass time of previously scheduled jobs, hurrah! Allow the job to be scheduled.
    if [ $allow = "TRUE" ]
      then
        #Echo job info for the record
        echo "===="
        echo "$1 at elevation $MAXELEV at $(date --date="@$var1" +"%-I:%M%^p %m/%d/%Y") scheduled"
        #Schedule the at job to call receive_and_process_satellite.sh with necessary arguments
        #Also kill output garbage from at command by stdout and stderr to /dev/null
        echo "/home/pi/weather/predict/receive_and_process_satellite.sh \"${1}\" $2 /home/pi/weather/${1//" "}${OUTDATE} /home/pi/weather/predict/weather.tle $var1 $TIMER $MAXELEV" | at `date --date="TZ=\"UTC\" $START_TIME" +"%H:%M %D"` > /dev/null 2>&1
    fi
  fi
  #Add 60 seconds to get the next prediction for this satellite today
  nextpredict=`expr $var2 + 60`
  #Get new prediction start/end values from TLE files resspectively
  PREDICTION_START=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" $nextpredict | head -1`
  PREDICTION_END=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}"  $nextpredict | tail -1`
  #Get new max elevation from new predictions.
  MAXELEV=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" $nextpredict | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`
  #Get new end time in epoch
  var2=`echo $PREDICTION_END | cut -d " " -f 1`
  #DO IT AGAIN (If today is still today, and not tomorrow)
done
