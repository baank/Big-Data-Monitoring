#!/bin/bash

SESSION_ID=`curl -s -k http://x.x.x.x:20000 -d "username=azkaban&password=azkaban&action=login" | grep "session.id" | awk '{print $3}' | cut -d'"' -f 2`
EXECUTION=`curl -s -k --get http://x.x.x.x:20000/manager -d "session.id=$SESSION_ID&ajax=fetchFlowExecutions&project=$1&flow=$2&start=0&length=1"`
END_TIME=`echo $EXECUTION | cut -d' ' -f 20 | cut -d',' -f 1`
STATUS=`echo $EXECUTION | cut -d'"' -f 26`
FORMATTED_END_TIME=`perl -e "print scalar(localtime($END_TIME/1000))"`
echo $FORMATTED_END_TIME - $STATUS
