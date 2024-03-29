FROM nvidia/cuda:11.8.0-devel-ubuntu20.04
# clean apt config
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBCONF_TERSE="yes"
ARG LANG="C.UTF-8"
ARG PIP_DISABLE_PIP_VERSION_CHECK=1

# Set locale
ENV LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get -y install \
  libcudnn8=8.9.5.29-1+cuda11.8 \
  libcudnn8-dev=8.9.5.29-1+cuda11.8 \
  build-essential \
  ca-certificates \
  # curl is used in this Dockerfile and others based on it, as well as Buildkite plugins
  curl \
  gzip \
  jq \
  patchelf \
  rsync \
  tar \
  unzip \
  zip \
  # Clean up
  && apt-get autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Setup ld.so.conf to find cuda stubs
COPY zz_cuda_stubs.conf /etc/ld.so.conf.d/
RUN ldconfig

# sandboxfs
RUN curl -L https://github.com/bazelbuild/sandboxfs/releases/download/sandboxfs-0.2.0/sandboxfs-0.2.0-20200420-linux-x86_64.tgz | tar xz -C /usr/local \
  && chmod +x /usr/local/bin/sandboxfs

# yq
RUN curl -LO https://github.com/mikefarah/yq/releases/download/v4.19.1/yq_linux_amd64 \
  && chmod +x yq_linux_amd64 \
  && mv yq_linux_amd64 /usr/local/bin/yq

RUN curl -sLO https://apt.llvm.org/llvm-snapshot.gpg.key \
  && apt-key add llvm-snapshot.gpg.key \
  # for UBUNTU_CODENAME
  && . /etc/os-release \
  && echo "deb http://apt.llvm.org/$UBUNTU_CODENAME/ llvm-toolchain-$UBUNTU_CODENAME-13 main" > /etc/apt/sources.list.d/clang-13.list \
  && apt-get update -q \
  && apt-get install -y clang-13 \
  && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-13 100 \
  && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-13 100 \
  && update-alternatives --set clang /usr/bin/clang-13 \
  && update-alternatives --set clang++ /usr/bin/clang++-13 \
  # Clean up
  && apt-get autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /tmp
