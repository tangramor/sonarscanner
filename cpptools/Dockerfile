FROM gcc:8

WORKDIR /root

# China mirror: mirrors.aliyun.com
ARG MIRROR=deb.debian.org

RUN if [ "$MIRROR" != "deb.debian.org" ]; then sed -i 's/deb.debian.org/'$MIRROR'/g' /etc/apt/sources.list; fi \
	&& apt-get update && apt-get install -y valgrind libssl-dev libc-dev tcl-dev lua5.1 python-dev lua5.1-dev libluabind-dev g++ make cmake \
	&& wget -c -t 0 -O cppcheck-master.zip https://github.com/danmar/cppcheck/archive/master.zip \
	&& unzip -a cppcheck-master.zip && cd cppcheck-master \
	&& make install CFGDIR=/cfg HAVE_RULES=yes CXXFLAGS="-O2 -DNDEBUG --static -pedantic -pthread -lpthread" -j `getconf _NPROCESSORS_ONLN` \
	&& strip /usr/bin/cppcheck && cd /root && rm -rf /root/cppcheck-master* \
	&& curl -L https://bitbucket.org/verateam/vera/downloads/vera++-1.3.0.tar.gz -o vera++-1.3.0.tar.gz \
	&& tar zxvf vera++-1.3.0.tar.gz \
	&& cd vera++-1.3.0 && mkdir build \
	&& cd ./build; cmake .. && make -j8 && make install \
	&& cd /root && rm -rf /root/vera* \
	&& apt-get autoremove && apt-get autoclean

COPY ./*.sh /usr/local/bin/

# To debug inside the container
CMD ["tail", "-f", "/dev/null"]
