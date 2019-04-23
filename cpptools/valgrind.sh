#!/bin/bash
cd /root
if [ ! -n "$1" ]; then
	echo "Input the compiled binary file name"
fi
valgrind --xml=yes --xml-file=valgrind_report.xml $1
