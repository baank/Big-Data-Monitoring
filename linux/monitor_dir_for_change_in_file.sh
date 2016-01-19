#!/bin/bash
#This Plug-in monitors the direcory for changes in file in last five minutes, if any of the files in that directory have changed in last five minutes and sends
#Critical Alert.

# Usage : monitor_dir_for_change_in_file.sh  /tmp

# Author - Juned Memon
#######################################################################################
#Nagios Exit Status
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4
########################################################################################

LOC=$1 # This defines the path of the directory to be monitored

COUNT=$(find $LOC -type f -mmin -5 | wc -l )
if [ $COUNT -gt 0 ] ; then #### We find some new files, now send the alert
exitstatus=$STATE_CRITICAL
echo "CRITICAL : $COUNT files have changed in last five minutes."
exit $exitstatus
else
exitstatus=$STATE_OK  #### everey thing looks fine
echo "OK : No files have changed in last five minutes"
exit $exitstatus
fi

 

