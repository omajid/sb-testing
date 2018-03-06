FROM rhel74prereq 
ARG pw
RUN git clone https://dleeapho:$pw@devdiv.visualstudio.com/DefaultCollection/DevDiv/_git/DotNet-Source-Build-Tarball

WORKDIR DotNet-Source-Build-Tarball

RUN ./build.sh || true
