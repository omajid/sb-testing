#FROM microsoft/dotnet-buildtools-prereqs:fedora-24-67592e6-20170219020243
#FROM microsoft/dotnet-buildtools-prereqs:rhel-7-rpmpkg-e1b4a89-20175311035359
FROM registry.access.redhat.com/rhel7
ARG PW
RUN subscription-manager register --username dleeapho-msft --password $PW --auto-attach

# Install the base toolchain we need to build anything (clang, cmake, make and the like)
# this does not include libraries that we need to compile different projects, we'd like
# them in a different layer.

# --- From Matt Ellis' dotnet-buildtools-prereqs rhel7 Docker file ---
# Our toolchain is CMake 3.3.2 from GhettoForge; LLVM 3.6.2 built from source ourselves; wget,
# which, and make (from RHEL).
RUN yum install -y https://matell.blob.core.windows.net/rpms/jsoncpp-0.10.5-1.el7.x86_64.rpm \
        https://matell.blob.core.windows.net/rpms/cmake-3.3.2-1.gf.el7.x86_64.rpm \
        https://matell.blob.core.windows.net/rpms/clang-3.6.2-3.el7.x86_64.rpm \
        https://matell.blob.core.windows.net/rpms/clang-libs-3.6.2-3.el7.x86_64.rpm \
        https://matell.blob.core.windows.net/rpms/lldb-3.6.2-3.el7.x86_64.rpm \
        https://matell.blob.core.windows.net/rpms/lldb-devel-3.6.2-3.el7.x86_64.rpm \
        https://matell.blob.core.windows.net/rpms/llvm-3.6.2-3.el7.x86_64.rpm \
        https://matell.blob.core.windows.net/rpms/llvm-libs-3.6.2-3.el7.x86_64.rpm \
        wget \
        which \
        make && \
    yum clean all

# Install tools used by the VSO build automation.  We use NodeJS from nodesource.com.
RUN yum install -y https://rpm.nodesource.com/pub_0.10/el/7/x86_64/nodesource-release-el7-1.noarch.rpm && \
    yum updateinfo && \
    yum install -y git \
        zip \
        tar \
        nodejs \
    yum clean all && \
    npm install -g azure-cli

# Dependencies of CoreCLR and CoreFX.  Everything except lttng is present in RHEL, for lttng we
# get the development packages from EfficiOS.
RUN wget -P /etc/yum.repos.d/ https://packages.efficios.com/repo.files/EfficiOS-RHEL7-x86-64.repo && \
    rpmkeys --import https://packages.efficios.com/rhel/repo.key && \
    yum updateinfo && \
    yum install --enablerepo=rhel-7-server-optional-rpms -y libicu-devel \
        libuuid-devel \
        libcurl-devel \
        openssl-devel \
        libunwind-devel \
        lttng-ust-devel && \
    yum clean all

# Define the en_US.UTF-8 locale (without this, processes MSBuild trys to launch complain about
# being unable to use the en_US.UTF-8 locale which can cause downstream failures if you capture
# the output of a run)
RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
# --- From Matt Ellis' dotnet-buildtools-prereqs rhel7 Docker file ---

RUN mkdir dnsb
WORKDIR dnsb

RUN curl -O https://matell.blob.core.windows.net/cli-src/cli-1.0.0-preview2-003200.tar.gz
RUN tar xvf cli-1.0.0-preview2-003200.tar.gz
WORKDIR cli-1.0.0-preview2-003200
RUN ./unpack-sources.sh
RUN yum install patch -y

#RUN ./apply-patches.sh
#RUN ./build.sh