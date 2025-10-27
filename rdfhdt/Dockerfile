FROM debian:bookworm-slim

# Install build deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    build-essential \
    cmake \
    autoconf \
    libtool \
    zlib1g \
    zlib1g-dev \
    pkg-config \
    libserd-0-0 \
    libserd-dev

# Build HDT
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/rdfhdt/hdt-cpp.git
WORKDIR /tmp/hdt-cpp
RUN ./autogen.sh \
    ./configure \
    make -j2 \
    sudo make install

CMD ["rdf2hdt", "--help"]
