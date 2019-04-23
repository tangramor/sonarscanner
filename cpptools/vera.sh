#!/bin/bash
cd /root
#find . -type f -regex ".*\.\(hpp\|cpp\|c\|h\)" | awk -F "/" '{ print "Vera++ Check "$0; print "vera++ -s -c vera_report_"$(NF-1)"_"$NF".xml "$0 | "/bin/bash"; }'

find . -type f -regex ".*\.\(hpp\|cpp\|c\|h\)" > ./cfiles.txt && vera++ -s -c vera_report.xml -i cfiles.txt && rm -f ./cfiles.txt
