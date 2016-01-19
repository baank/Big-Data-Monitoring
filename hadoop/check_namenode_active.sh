#!/bin/bash

status=$(curl -m 5 -s http://hdp001-nn:50070/jmx?qry=Hadoop:service=NameNode,name=FSNamesystem | grep -i "tag.HAState" | grep -o -E "standby|active")

if [ "$status" == "active" ]; then
  echo "OK: hdp001-nn is active"
  exit 0
else
  echo "CRTICIAL: hdp001-nn is standby"
  exit 2
fi
