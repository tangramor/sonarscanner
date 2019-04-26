## 使用 docker 运行 sonarqube 扫描器 并 支持 C++ 与 C

受 https://hub.docker.com/r/zaquestion/sonarqube-scanner 启发，因为该容器不包含 nodejs，在扫描时会有缺陷，故自己做了一个镜像。

扫描器镜像：[tangramor/sonarscanner](https://hub.docker.com/r/tangramor/sonarscanner)。

为了支持 C++/C，我构建了一个提供各种相关开源工具的镜像：[tangramor/cpptools](https://hub.docker.com/r/tangramor/cpptools).


### 使用方法

可以使用 [docker-compose](https://github.com/SonarSource/docker-sonarqube/blob/master/recipes/docker-compose-postgres-example.yml) 来启动一个 sonarqube 实例，当然也可以自己搭建。要支持 C++/C，需要安装 [sonar-cxx](https://github.com/SonarOpenCommunity/sonar-cxx) (要支持 Sonarqube 7.7，需下载 [1.3.0 版本](https://ci.appveyor.com/project/SonarOpenCommunity/sonar-cxx/builds/23281379/artifacts)) 插件。

为了支持包含很多源码文件的大项目，你可能需要对配置文件 `/opt/sonarqube/conf/sonar.properties` 进行微调，增加计算引擎的可使用内存（缺省512M）：
```
sonar.ce.javaOpts=-Xmx1024m -Xms128m -XX:+HeapDumpOnOutOfMemoryError
```

在你要扫描的项目根目录添加 `sonar-project.properties` 文件。下面是一个 Java 的例子：
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

然后在你要扫描的项目根目录下运行扫描：
```
docker run --name sonarscan -it -e JAVA_Xmx=3062m --network sonarqube_sonarnet -v $(pwd):/root/src tangramor/sonarscanner && docker rm sonarscan
```

在运行时可以使用 `-e` 传入一些环境变量以修改 JVM 的内存设置，当然在修改前需要确保你有足够的内存：

* `JAVA_Xmx`: 缺省值 2048m
* `JAVA_MaxPermSize`: 缺省值 512m
* `JAVA_ReservedCodeCacheSize`: 缺省值 128m
* `SONAR_SCANNER_OPTS`: 这个环境变量把前面3个参数合并为真正输入给扫描器的参数 (缺省值： `"-Xmx2048m -XX:MaxPermSize=512m -XX:ReservedCodeCacheSize=128m"`)，你也可以不设置前面3个，对这个进行单独设置，例如：`"-Xmx3062m -XX:MaxPermSize=1024m -XX:ReservedCodeCacheSize=128m"`。


### 构建自己的扫描器 docker 镜像

最新版本的扫描器安装包可以从 https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner 找到。

例如：https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-3.3.0.1492-linux.zip ，在构建镜像时你需要指定 `LATEST=3.3.0.1492-linux`。

你可以把下载好的扫描器安装包放置到 Dockerfile 所在的目录下，这样就不用在构建过程中由脚本自动再下载一次了，当然你还是需要指定 `LATEST` 参数，构建脚本会自动判断是不是需要下载。

**构建镜像** (这里我们输入了两个参数，一个是上面提到的扫描器版本，一个是制定 alpine 镜像以加快构建速度)：
```
docker build -t tangramor/sonarscanner --build-arg LATEST=3.3.0.1492-linux --build-arg APKMIRROR=mirrors.ustc.edu.cn .
```


### 支持 C++ 项目

社区版的 Sonarqube **不支持** C++/C 扫描，相关插件属于商业授权，需要购买。于是有高尚的开发者创建了 [sonar-cxx](https://github.com/SonarOpenCommunity/sonar-cxx) 插件，作为自由软件分发。不过不管是商业版还是自由版，都需要使用到外部工具。

我创建了 `tangramor/cpptools` docker 镜像，其中包含了 C++ 和 C 的编译器 gcc/g++，sonar-cxx 支持的静态分析工具 `valgrind` ([valgrind 使用手册](http://valgrind.org/docs/manual/manual.html))、`cppcheck` ([cppcheck 使用手册](http://cppcheck.sourceforge.net/manual.html)) 、 `vera++` ([vera++ 使用手册](https://bitbucket.org/verateam/vera/wiki/Running)) 以及覆盖率检测工具 `gcovr` ([gcovr 使用手册](https://www.gcovr.com/en/stable/guide.html))。这些工具可以生成能够导入 sonarqube 的 XML 格式的结果报告：

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

注意，上面的 vera++ 命令一次只能扫描一个源代码文件。我在 `tangramor/cpptools` 镜像里内置了脚本，可以找出当前目录下的所有 C++ 或 C 语言源码文件或头文件，并通过 vera++ 扫描后生成一个报告文件。其它命令也提供了对应脚本：

```
docker run --name valgrind -v $(pwd):/root tangramor/cpptools valgrind.sh ./test && docker rm valgrind

docker run --name cppcheck -v $(pwd):/root tangramor/cpptools cppcheck.sh && docker rm cppcheck

docker run --name vera -v $(pwd):/root tangramor/cpptools vera.sh && docker rm vera

docker run --name gcovr -v $(pwd):/root tangramor/cpptools gcovr.sh && docker rm gcovr
```

要支持 C++，需要在 `sonar-project.properties` 添加下面的设置：

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


然后在你的项目根目录下执行扫描：
```
docker run --name sonarscan -it -e JAVA_Xmx=3062m --network sonarqube_sonarnet -v $(pwd):/root/src tangramor/sonarscanner && docker rm sonarscan
```


