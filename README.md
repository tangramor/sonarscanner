## Use sonarqube scanner with docker and support C++

Inspired from https://hub.docker.com/r/zaquestion/sonarqube-scanner

It does not contain nodejs, so build our own scanner docker image.

Get latest scanner from https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner

For example: https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip

You can save the zip file in the same directory of the Dockerfile, or you can just give the `LATEST` value.


**Build image** (here we input 2 args, one for sonar scanner version, one for alpine mirror):
```
docker build -t tangramor/sonarscanner --build-arg LATEST=3.3.0.1492-linux --build-arg APKMIRROR=mirrors.ustc.edu.cn .
```

Exmaple `sonar-project.properties` in your project, here we assume that you have a sonarqube instance started using [docker-compose](https://github.com/SonarSource/docker-sonarqube/blob/master/recipes/docker-compose-postgres-example.yml):
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

# Work with the dockerized Sonarqube
sonar.host.url=http://sonarqube:9000

```

Execute scan under your project:
```
docker run --name sonarscan -it --network sonar_sonarnet -v $(pwd):/root/src tangramor/sonarscanner && docker rm sonarscan
```


### For C++ project

```
docker run --name compile -v $(pwd):/root tangramor/cpptools g++ -std=c++11 -lcrypto Test.cpp -o test && docker rm compile

docker run --name valgrind -v $(pwd):/root tangramor/cpptools valgrind --xml=yes --xml-file=valgrind_report.xml ./test && docker rm valgrind

docker run --name cppcheck -v $(pwd):/root tangramor/cpptools cppcheck . --enable=all -v --xml 2> cppcheck_report.xml && docker rm cppcheck

docker run --name vera -v $(pwd):/root tangramor/cpptools vera++ -s -c vera_report.xml ./Test.cpp && docker rm vera
```

Please be aware that vera++ command above can only scan 1 source code file one time. You may use the shell scripts in the docker image, which will find out all the C++/C files/headers and scan them:

```
docker run --name valgrind -v $(pwd):/root tangramor/cpptools valgrind.sh ./test && docker rm valgrind

docker run --name cppcheck -v $(pwd):/root tangramor/cpptools cppcheck.sh && docker rm cppcheck

docker run --name vera -v $(pwd):/root tangramor/cpptools vera.sh && docker rm vera
```

[vera++ usage](https://bitbucket.org/verateam/vera/wiki/Running)


Add related report path in `sonar-project.properties`:

```
sonar.language=c++
sonar.cxx.cppcheck.reportPath=./cppcheck_report.xml
sonar.cxx.valgrind.reportPath=./valgrind_report.xml
sonar.cxx.vera.reportPath=./vera_report.xml
```


Execute scan under your project:
```
docker run --name sonarscan -it --network sonar_sonarnet -v $(pwd):/root/src tangramor/sonarscanner && docker rm sonarscan
```


