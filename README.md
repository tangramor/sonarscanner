## Use sonarqube scanner with docker and support C++

Inspired from https://hub.docker.com/r/zaquestion/sonarqube-scanner

It does not contain nodejs, so I build my own scanner docker image: [tangramor/sonarscanner](https://hub.docker.com/r/tangramor/sonarscanner).

And to support C++/C, I build another docker image to provide some open source tools: [tangramor/cpptools](https://hub.docker.com/r/tangramor/cpptools).


### Scanner Usage

You can create a sonarqube instance by [docker-compose](https://github.com/SonarSource/docker-sonarqube/blob/master/recipes/docker-compose-postgres-example.yml). To support C++/C, you need to install [sonar-cxx](https://github.com/SonarOpenCommunity/sonar-cxx) (To support Sonarqube 7.7, download 1.3.0 [here](https://ci.appveyor.com/project/SonarOpenCommunity/sonar-cxx/builds/23281379/artifacts)).

To support large project which has many source code files, you may need to tunning `/opt/sonarqube/conf/sonar.properties` and increase the memory allocation for Compute Engine (default 512m):
```
sonar.ce.javaOpts=-Xmx1024m -Xms128m -XX:+HeapDumpOnOutOfMemoryError
```

Add a `sonar-project.properties` in your project, following is an example for Java.
```
# Required metadata
sonar.projectKey=my-sonar-test
sonar.projectName=Java :: My Test Project
sonar.projectVersion=1.0
sonar.login=07ec1d40680ba21388a46185f3e217c7a36add11

# Comma-separated paths to directories with sources (required)
sonar.sources=.

# Language
sonar.language=java

# Where to find compiled binaries
sonar.java.binaries=./Java/bin

# Encoding of the source files
sonar.sourceEncoding=UTF-8

# Work with the dockerized Sonarqube on the same machine
sonar.host.url=http://sonarqube:9000

```

Execute scan under your project:
```
docker run --name sonarscan -it -e JAVA_Xmx=3062m --network sonarqube_sonarnet -v $(pwd):/root/src tangramor/sonarscanner && docker rm sonarscan
```

There are some environment parameters which can be passed in with `-e`, before set them, make sure you have enough memory:

* `JAVA_Xmx`: default value is 2048m
* `JAVA_MaxPermSize`: default value is 512m
* `JAVA_ReservedCodeCacheSize`: default value is 128m
* `SONAR_SCANNER_OPTS`: this parameter combine the above 3 paramters to 1 (default value: `"-Xmx2048m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=128m"`), you can set it alone without above parameters like this: `"-Xmx3062m -XX:MaxPermSize=1024m -XX:ReservedCodeCacheSize=128m"`


### Build Scanner Image

You can find the latest scanner from https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner

For example: https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip , for it we need to set `LATEST=3.3.0.1492-linux`.

You can save the zip file in the same directory of the Dockerfile, or you can only give the `LATEST` value.

**Build image** (here we input 2 args, one for sonar scanner version, one for alpine mirror):
```
docker build -t tangramor/sonarscanner --build-arg LATEST=3.3.0.1492-linux --build-arg APKMIRROR=mirrors.ustc.edu.cn .
```


### For C++ Project

The community editon Sonarqube does NOT support C++/C scan, you need to buy the commercial license. It is lucky that there are some great people created [sonar-cxx](https://github.com/SonarOpenCommunity/sonar-cxx) as free software. However, it needs some external C++/C tools to generate reports.

Following commands use docker image `tangramor/cpptools` to compile C++ program, and scan it with `valgrind` ([valgrind usage](http://valgrind.org/docs/manual/manual.html)), `cppcheck` ([cppcheck usage](http://cppcheck.sourceforge.net/manual.html)) and `vera++` ([vera++ usage](https://bitbucket.org/verateam/vera/wiki/Running)), and check coverage with `gcovr` ([gcovr usage](https://www.gcovr.com/en/stable/guide.html)), and generate XML reports which can be imported into sonarqube:

```
# -fdiagnostics-show-option is needed to generate build log
# -fprofile-arcs -ftest-coverage -fPIC is needed by gcovr
docker run --name compile -v $(pwd):/root tangramor/cpptools g++ -std=c++11 -Wall -fdiagnostics-show-option -lcrypto -fprofile-arcs -ftest-coverage -fPIC -O0 Test.cpp -o test > build.log 2>&1 && docker rm compile

# This step will execute the compiled program and generate .gcda file needed by gcovr
docker run --name valgrind -v $(pwd):/root tangramor/cpptools valgrind --xml=yes --xml-file=valgrind_report.xml ./test && docker rm valgrind

docker run --name cppcheck -v $(pwd):/root tangramor/cpptools cppcheck . --enable=all -v --xml 2> cppcheck_report.xml && docker rm cppcheck

docker run --name vera -v $(pwd):/root tangramor/cpptools vera++ -s -c vera_report.xml ./Test.cpp && docker rm vera

docker run --name gcovr -v $(pwd):/root tangramor/cpptools gcovr -r . -x > gcovr_report.xml && docker rm gcovr
```

Please be aware that vera++ command above can only scan 1 source code file one time. You may use the shell scripts I placed in the docker image, which will find out all the C++/C files/headers and scan them:

```
docker run --name valgrind -v $(pwd):/root tangramor/cpptools valgrind.sh ./test && docker rm valgrind

docker run --name cppcheck -v $(pwd):/root tangramor/cpptools cppcheck.sh && docker rm cppcheck

docker run --name vera -v $(pwd):/root tangramor/cpptools vera.sh && docker rm vera

docker run --name gcovr -v $(pwd):/root tangramor/cpptools gcovr.sh && docker rm gcovr
```

Add related report path in `sonar-project.properties`:

```
sonar.language=c++

sonar.cxx.gcc.reportPath=*.log
sonar.cxx.gcc.charset=UTF-8
sonar.cxx.gcc.regex=(?<file>.*):(?<line>[0-9]+):[0-9]+:\\x20warning:\\x20(?<message>.*)\\x20\\[(?<id>.*)\\]

sonar.cxx.cppcheck.reportPath=./cppcheck_report.xml
sonar.cxx.valgrind.reportPath=./valgrind_report.xml
sonar.cxx.vera.reportPath=./vera_report.xml
sonar.cxx.coverage.reportPath=./gcovr_report.xml
```


Execute scan under your project:
```
docker run --name sonarscan -it -e JAVA_Xmx=3062m --network sonarqube_sonarnet -v $(pwd):/root/src tangramor/sonarscanner && docker rm sonarscan
```


