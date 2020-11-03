FROM openjdk:11-jre-slim

WORKDIR /root

ENV SONAR_RUNNER_HOME=/root/sonar_home \
    PATH=${SONAR_RUNNER_HOME}/bin:$PATH \
    JAVA_HOME=/usr/local/openjdk-11 \
    ASPNETCORE_URLS=http://+:80 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Set the invariant mode since icu_libs isn't included (see https://github.com/dotnet/announcements/issues/20)
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=true

# China mirror: ftp2.cn.debian.org/debian/
ARG DEBIANMIRROR=cdn-fastly.deb.debian.org

RUN if [ "$DEBIANMIRROR" != "cdn-fastly.deb.debian.org" ]; then sed -i 's/deb.debian.org/'$DEBIANMIRROR'/g' /etc/apt/sources.list; fi \
  && apt update && apt install -y curl wget git python3 python3-pip nodejs openssl unzip \
        libgssapi-krb5-2 \
        libintl-perl \
        libssl1.0 \
        libstdc++-arm-none-eabi-newlib \
        liblttng-ust-java \
        tzdata \
        liburcu6 \
        zlib1g \
        gcc make python3-dev libc-dev \
  && update-ca-certificates \
  && pip3 install --upgrade pip pylint setuptools -i https://pypi.tuna.tsinghua.edu.cn/simple \
  # install DotNet
  # https://download.visualstudio.microsoft.com/download/pr/933b0cb8-3494-4ca4-8c9e-1bcfd3568ab0/8704eef073efdfecdaaad4a18beb05ac/aspnetcore-runtime-3.1.9-linux-x64.tar.gz
  && wget -O dotnet.tar.gz https://download.visualstudio.microsoft.com/download/pr/933b0cb8-3494-4ca4-8c9e-1bcfd3568ab0/8704eef073efdfecdaaad4a18beb05ac/aspnetcore-runtime-3.1.9-linux-x64.tar.gz \
  && dotnet_sha512='86462c61dd71adda38ddb0178fc44591cde13de4357652365e0d5c80d14db98d2e1f14a6fab2455b9deebcb910577174473d86f432dd3cd3d0b4284a9dcf440f' \
  && echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - \
  && mkdir -p /usr/share/dotnet \
  && tar -C /usr/share/dotnet -xzf dotnet.tar.gz \
  && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
  && rm dotnet.tar.gz \
  # clean
  && apt-get -y autoclean && apt-get -y autoremove \
	&& rm -rf /var/lib/apt/lists/*

ARG LATEST=4.5.0.2216-linux
# https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner
# Example: https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.5.0.2216-linux.zip
# Run: docker build -t sonarscanner --build-arg LATEST=3.3.0.1492-linux .

# You may already downloaded the scanner package and placed it in current folder
COPY ./* /root/

RUN env \
  && if [ ! -f /root/sonar-scanner-cli-$LATEST.zip ]; then wget -c -t 0 https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$LATEST.zip; fi \
  && mkdir sonar_home && unzip -a sonar-scanner-cli-$LATEST.zip && mv sonar-scanner*/* sonar_home/ && rm -rf sonar-scanner-cli-$LATEST.zip \
  && sed -i 's/use_embedded_jre=true/echo "SONAR_SCANNER_OPTS: $SONAR_SCANNER_OPTS"\nJAVA_HOME=$JAVA_HOME\nuse_embedded_jre=false\n/g' /root/sonar_home/bin/sonar-scanner \
  && sed -i 's/usr\/bin\/env sh/bin\/bash/g' /root/sonar_home/bin/sonar-scanner \
  && ln -s /root/sonar_home/bin/sonar-scanner /usr/local/bin/sonar-scanner \
  && ln -s /root/sonar_home/bin/sonar-scanner-debug /usr/local/bin/sonar-scanner-debug

# The maximum memory allocation for JVM
ENV JAVA_Xmx=2048m
ENV JAVA_ReservedCodeCacheSize=128m

# ENV SONAR_SCANNER_OPTS="-Xmx3062m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=128m"
ENV SONAR_SCANNER_OPTS="-Xmx$JAVA_Xmx -XX:ReservedCodeCacheSize=$JAVA_ReservedCodeCacheSize"

CMD sonar-scanner -Dsonar.projectBaseDir=./src

