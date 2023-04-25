FROM ghcr.io/graalvm/graalvm-ce:22.3.1 as builder

WORKDIR /app
COPY . /app

RUN gu install native-image

# BEGIN PRE-REQUISITES FOR STATIC NATIVE IMAGES FOR GRAAL
# SEE: https://github.com/oracle/graal/blob/master/substratevm/StaticImages.md
ARG RESULT_LIB="/staticlibs"

RUN mkdir ${RESULT_LIB}

RUN cd ${RESULT_LIB} && \
    curl -L -s -o musl.tar.gz https://more.musl.cc/10/x86_64-linux-musl/x86_64-linux-musl-native.tgz && \
    tar -xzf musl.tar.gz

ARG TOOLCHAIN_DIR="${RESULT_LIB}/x86_64-linux-musl-native"
ARG CC="${TOOLCHAIN_DIR}/bin/gcc"

RUN cd ${RESULT_LIB} && \
    curl -L -s -o zlib.tar.gz https://zlib.net/zlib-1.2.13.tar.gz && \
    tar -xzf zlib.tar.gz && \
    cd zlib-1.2.13 && \
    ./configure --static --prefix=${TOOLCHAIN_DIR} &>/dev/null && \
    make -s && make install -s
#END PRE-REQUISITES FOR STATIC NATIVE IMAGES FOR GRAAL


RUN cd ${RESULT_LIB} && \
    curl -L -s -o xz-libs.rpm https://rpmfind.net/linux/centos-stream/9-stream/BaseOS/x86_64/os/Packages/xz-libs-5.2.5-8.el9.x86_64.rpm && \
    rpm -iv --force xz-libs.rpm && \
    rm -f xz-libs.rpm && \
    curl -L -s -o xz.rpm https://rpmfind.net/linux/centos-stream/9-stream/BaseOS/x86_64/os/Packages/xz-5.2.5-8.el9.x86_64.rpm && \
    rpm -iv xz.rpm && \
    rm -f xz.rpm && \
    curl -L -s -o upx-amd64_linux.tar.xz https://github.com/upx/upx/releases/download/v4.0.1/upx-4.0.1-amd64_linux.tar.xz && \
    tar -xf upx-amd64_linux.tar.xz && \
    rm -f upx-amd64_linux.tar.xz

ENV PATH="$PATH:${TOOLCHAIN_DIR}/bin"

RUN cd /app && ./sbt clean stage

RUN ls target/universal/stage/lib/

RUN cd /app && native-image \
    -jar target/universal/stage/lib/*-launcher.jar \
    --no-fallback \
    --static \
    --libc=musl \
    --initialize-at-run-time=io.netty.channel.DefaultFileRegion \
    --initialize-at-run-time=io.netty.channel.epoll.Native \
    --initialize-at-run-time=io.netty.channel.epoll.Epoll \
    --initialize-at-run-time=io.netty.channel.epoll.EpollEventLoop \
    --initialize-at-run-time=io.netty.channel.epoll.EpollEventArray \
    --initialize-at-run-time=io.netty.channel.kqueue.KQueue \
    --initialize-at-run-time=io.netty.channel.kqueue.KQueueEventLoop \
    --initialize-at-run-time=io.netty.channel.kqueue.KQueueEventArray \
    --initialize-at-run-time=io.netty.channel.kqueue.Native \
    --initialize-at-run-time=io.netty.channel.unix.Limits \
    --initialize-at-run-time=io.netty.channel.unix.Errors \
    --initialize-at-run-time=io.netty.channel.unix.IovArray \
    --initialize-at-run-time=io.netty.handler.codec.compression.ZstdOptions \
    --initialize-at-run-time=io.netty.handler.ssl.BouncyCastleAlpnSslUtils \
    --initialize-at-run-time=io.netty.incubator.channel.uring.IOUringEventLoopGroup \
    hello-scala-gni-buildpacks

RUN ${RESULT_LIB}/upx-4.0.1-amd64_linux/upx -7 /app/hello-scala-gni-buildpacks

FROM scratch

WORKDIR /tmp

COPY --from=builder /app/hello-scala-gni-buildpacks /hello-scala-gni-buildpacks

ENTRYPOINT ["/hello-scala-gni-buildpacks"]
