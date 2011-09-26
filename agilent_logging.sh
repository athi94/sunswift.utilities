#!/bin/bash
LOGFILE=../data/ch_log.txt
LOG_INTERVAL=10			# duration between samples
#LOG_TIME=100				#-1 - sets infinite time

#LOG_TIME=$(LOG_TIME)+("date +%s")
TIME=`date +%s`
echo "log started at" $TIME >> $LOGFILE

while [ 1 ]
do
	VOLTAGE=`./u1272a.pl | grep reading: | cut -f2 -d" "`
	TIME=`date +%s`
	echo $VOLTAGE $TIME >> $LOGFILE
	echo $VOLTAGE $TIME
	sleep $LOG_INTERVAL
done
