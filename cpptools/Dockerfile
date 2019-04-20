# compile error in alpine...
# FROM alpine:3.9
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && apk update && apk add --no-cache valgrind openssl-dev g++ build-base alpine-sdk

FROM gcc:8

WORKDIR /root

# China mirror: mirrors.aliyun.com
ARG MIRROR=deb.debian.org

RUN if [ "$MIRROR" != "deb.debian.org" ]; then sed -i 's/deb.debian.org/'$MIRROR'/g' /etc/apt/sources.list; fi \
	&& apt-get update && apt-get install -y valgrind libssl-dev g++ make \
	&& git clone https://github.com/danmar/cppcheck.git \
	&& cd cppcheck \
	&& make install CFGDIR=/cfg HAVE_RULES=yes CXXFLAGS="-O2 -DNDEBUG --static" -j `getconf _NPROCESSORS_ONLN` \
	&& strip /usr/bin/cppcheck \
	&& apt-get autoremove && apt-get autoclean
