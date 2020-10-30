#!/bin/bash

docker build -t tangramor/sonarscanner --build-arg DEBIANMIRROR=mirrors.aliyun.com .
