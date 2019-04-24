#!/bin/bash
cd /root
gcovr -r . -x > gcovr_report.xml
