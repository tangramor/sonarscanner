## Use a sonarqube scanner with docker

Inspired from https://hub.docker.com/r/zaquestion/sonarqube-scanner

It does not contain nodejs, so build our own scanner docker image.

Get latest scanner from https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner
For example: https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip
You can save the zip file in the same directory of the Dockerfile, or you can just give the `LATEST` value.

Build image:
```
docker build -t sonarscanner --build-arg LATEST=3.3.0.1492-linux .
```

Exmaple `sonar-project.properties` in your project:
```
# Required metadata
sonar.projectKey=org.sonarqube:python-sonar-scanner
sonar.projectName=Python :: PYTHON! : SonarQube Scanner
sonar.projectVersion=1.0

# Comma-separated paths to directories with sources (required)
sonar.sources=<SRC>

# Language
sonar.language=py

# Encoding of the source files
sonar.sourceEncoding=UTF-8

sonar.host.url=http://172.17.0.5:9000
```

Execute scan under your project:
```
docker run --name sonarscan -it -v $(pwd):/root/src sonarscanner && docker rm sonarscan
```