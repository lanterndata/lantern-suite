ARG PG_VERSION=15
ARG LANTERN_VERSION=0.2.0
ARG LANTERN_EXTRAS_VERSION=0.1.3

FROM postgres:$PG_VERSION-bookworm
ARG LANTERN_VERSION
ARG LANTERN_EXTRAS_VERSION
ARG PG_VERSION
ARG TARGETARCH
ENV OS_ARCH="${TARGETARCH:-amd64}"

RUN apt update && apt install -y curl wget make jq pgbouncer procps bc

# Install Lantern
RUN cd /tmp && \
    wget https://github.com/lanterndata/lantern/releases/download/v${LANTERN_VERSION}/lantern-${LANTERN_VERSION}.tar -O lantern.tar && \
    tar xf lantern.tar && \
    cd lantern-${LANTERN_VERSION} && \
    make install && \
    cd /tmp && \
    rm -rf lantern*

# Install extras
RUN cd /tmp && \
    wget https://github.com/lanterndata/lantern_extras/releases/download/${LANTERN_EXTRAS_VERSION}/lantern-extras-${LANTERN_EXTRAS_VERSION}.tar -O lantern-extras.tar && \
    tar xf lantern-extras.tar && \
    cd lantern-extras-${LANTERN_EXTRAS_VERSION} && \
    make install && \
    cd /tmp && \
    rm -rf lantern-extras*

# Setup onnxruntime for lantern extras
RUN cd /tmp && \
    ONNX_VERSION="1.16.1" && \
    PACKAGE_URL="https://github.com/microsoft/onnxruntime/releases/download/v${ONNX_VERSION}/onnxruntime-linux-x64-${ONNX_VERSION}.tgz" && \
    if [[ $OS_ARCH == *"arm"* ]]; then PACKAGE_URL="https://github.com/microsoft/onnxruntime/releases/download/v${ONNX_VERSION}/onnxruntime-linux-aarch64-${ONNX_VERSION}.tgz"; fi && \
    mkdir -p /usr/local/lib && \
    cd /usr/local/lib && \
    wget $PACKAGE_URL && \
    tar xzf ./onnx*.tgz && \
    rm -rf ./onnx*.tgz && \
    mv ./onnx* ./onnxruntime && \
    echo /usr/local/lib/onnxruntime/lib > /etc/ld.so.conf.d/onnx.conf && \
    ldconfig

# Install Libssl
RUN cd /tmp && \
    wget "http://http.us.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1w-0+deb11u1_${OS_ARCH}.deb" && \
    dpkg -i "libssl1.1_1.1.1w-0+deb11u1_${OS_ARCH}.deb" && \
    rm -rf "libssl1.1_1.1.1w-0+deb11u1_${OS_ARCH}.deb"

# Cleanup
RUN apt-get autoremove --purge -y curl wget make && \
    apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY entrypoint/* /docker-entrypoint-initdb.d/
COPY scripts/*.sh /opt
COPY docker-entrypoint.sh /usr/local/bin/

USER postgres
EXPOSE 5432
EXPOSE 6432
