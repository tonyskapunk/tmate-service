FROM quay.io/centos/centos:stream8 AS build

RUN dnf install -y \
    epel-release

RUN dnf install -y \
    autoconf \
    automake \
    cmake \
    gcc-c++ \
    git \
    kernel-headers \
    libevent-devel \
    libssh-devel \
    msgpack-devel \
    ncurses-devel \
    openssl-devel \
    zlib-devel
    
RUN mkdir -p /src/tmate-ssh-server
COPY ./tmate-ssh-server /src/tmate-ssh-server

RUN set -ex; \
    cd /src/tmate-ssh-server; \
    ./autogen.sh; \
    ./configure --prefix=/usr CFLAGS="-D_GNU_SOURCE"; \
    make -j "$(nproc)"; \
    make install

FROM quay.io/centos/centos:stream8

RUN dnf install -y \
    epel-release

RUN dnf install -y \
    glibc-langpack-en \
    libevent \
    libssh \
    msgpack \
    ncurses-libs \
    openssl \
    zlib

COPY --from=build /usr/bin/tmate-ssh-server /usr/bin/

COPY ./tmate-ssh-server/docker-entrypoint.sh /usr/local/bin

ENTRYPOINT ["docker-entrypoint.sh"]
