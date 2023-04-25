Hello Scala GraalVM Native Image Buildpacks
-------------------------------------------

With Buildpacks:
```
pack build hello-scala-gni-buildpacks --builder paketobuildpacks/builder:tiny
```


For debugging with GraalVM installed:
```
./sbt stage
java -jar target/universal/stage/lib/default.hello-scala-gni-buildpacks-0.1.0-SNAPSHOT-launcher.jar
native-image -jar target/universal/stage/lib/default.hello-scala-gni-buildpacks-0.1.0-SNAPSHOT-launcher.jar --no-fallback hello-scala-gni-buildpacks
./hello-scala-gni-buildpacks
```
