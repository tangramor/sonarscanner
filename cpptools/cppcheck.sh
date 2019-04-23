#!/bin/bash
cd /root
cppcheck . --enable=all -v --xml 2> cppcheck_report.xml
