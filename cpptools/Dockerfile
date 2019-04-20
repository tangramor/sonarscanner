# compile error in alpine...
# FROM alpine:3.9
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk update && apk add --no-cache valgrind openssl-dev g++ build-base alpine-sdk

FROM gcc:8

WORKDIR /root

# China mirror: mirrors.aliyun.com
ARG MIRROR=deb.debian.org

RUN if [ "$MIRROR" != "deb.debian.org" ]; then sed -i 's/deb.debian.org/'$MIRROR'/g' /etc/apt/sources.list; fi \
	&& apt-get update && apt-get install -y valgrind libssl-dev g++ make \
	&& wget -c -t 0 -O cppcheck-master.zip https://github.com/danmar/cppcheck/archive/master.zip \
	&& unzip -a cppcheck-master.zip && cd cppcheck-master \
	&& make install CFGDIR=/cfg HAVE_RULES=yes CXXFLAGS="-O2 -DNDEBUG --static" -j `getconf _NPROCESSORS_ONLN` \
	&& strip /usr/bin/cppcheck && cd /root && rm -rf /root/cppcheck-master* \
	&& apt-get autoremove && apt-get autoclean
