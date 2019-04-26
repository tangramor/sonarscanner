FROM openjdk:8-jre-alpine

WORKDIR /root

ENV SONAR_RUNNER_HOME=/root/sonar_home
ENV PATH=${SONAR_RUNNER_HOME}/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre

# China mirror: mirrors.ustc.edu.cn
ARG APKMIRROR=dl-cdn.alpinelinux.org

RUN if [ "$APKMIRROR" != "dl-cdn.alpinelinux.org" ]; then sed -i 's/dl-cdn.alpinelinux.org/'$APKMIRROR'/g' /etc/apk/repositories; fi \
  && apk update && apk add --no-cache curl git python3 nodejs openssl unzip \
  && update-ca-certificates \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
  && python3 get-pip.py \
  && apk add --no-cache --virtual .build-deps-py gcc make python3-dev libc-dev \
  && pip install --upgrade pip pylint setuptools \
  && apk del .build-deps-py

ARG LATEST=3.3.0.1492-linux
# https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner
# Example: https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip
# Run: docker build -t sonarscanner --build-arg LATEST=3.3.0.1492-linux .

# You may already downloaded the scanner package and placed it in current folder
COPY ./* /root/

RUN env \
  && if [ ! -f /root/sonar-scanner-cli-$LATEST.zip ]; then wget -c -t 0 https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$LATEST.zip; fi \
  && mkdir sonar_home && unzip -a sonar-scanner-cli-$LATEST.zip && mv sonar-scanner*/* sonar_home/ && rm -rf sonar-scanner-cli-$LATEST.zip \
  && sed -i 's/use_embedded_jre=true/echo "SONAR_SCANNER_OPTS: $SONAR_SCANNER_OPTS"\nJAVA_HOME=$JAVA_HOME\nuse_embedded_jre=false\n/g' /root/sonar_home/bin/sonar-scanner

# The maximum memory allocation for JVM
ENV JAVA_Xmx=2048m
ENV JAVA_MaxPermSize=512m
ENV JAVA_ReservedCodeCacheSize=128m

# ENV SONAR_SCANNER_OPTS="-Xmx3062m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=128m"
ENV SONAR_SCANNER_OPTS="-Xmx$JAVA_Xmx -XX:MaxPermSize=$JAVA_MaxPermSize -XX:ReservedCodeCacheSize=$JAVA_ReservedCodeCacheSize"

CMD sonar-scanner -Dsonar.projectBaseDir=./src

