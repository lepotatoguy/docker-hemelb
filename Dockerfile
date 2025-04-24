FROM dorowu/ubuntu-desktop-lxde-vnc:focal
LABEL "CORE_MAINTAINER"="Miguel O. Bernabeu (miguel.bernabeu@ed.ac.uk)"
LABEL MAINTAINER="Joyanta J. Mondal (joyanta@udel.edu)"
LABEL VERSION="2.0"
# https://hub.docker.com/r/dorowu/ubuntu-desktop-lxde-vnc/

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# -------------------------
# Install system dependencies
# -------------------------
# Fix missing Chrome GPG key BEFORE update
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    wget curl git sudo gnupg2 software-properties-common \
    build-essential cmake cmake-curses-gui \
    libopenmpi-dev openmpi-bin \
    libtinyxml-dev libboost-all-dev libcgal-dev libctemplate-dev \
    ca-certificates apt-transport-https lsb-release \
    xz-utils jq && \
    apt-get install -y libopengl0 libxt6 libosmesa6 libglx0 python3-wxgtk4.0 &&\
    rm -rf /var/lib/apt/lists/*

# Set up GCC-13 from the Toolchain Test PPA manually
RUN apt-get update && \
    apt-get install -y software-properties-common gnupg2 wget && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BA9EF27F && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y gcc-13 g++-13 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100

# RUN apt-get install gcc-9 



# -------------------------
# Install Anaconda (For Python 3.8.20)
# -------------------------
RUN wget https://repo.anaconda.com/archive/Anaconda3-2024.02-1-Linux-x86_64.sh -O anaconda.sh && \
    bash anaconda.sh -b -p $CONDA_DIR && \
    rm anaconda.sh && \
    $CONDA_DIR/bin/conda clean -afy

# -------------------------
# Fix Chrome GPG and install Chrome
# -------------------------
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub -o /tmp/linux_signing_key.pub && \
    gpg --dearmor --batch < /tmp/linux_signing_key.pub > /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/* /tmp/linux_signing_key.pub


# -------------------------
# Clone and build HemeLB
# -------------------------
WORKDIR /opt
RUN git clone https://github.com/lepotatoguy/hemelb.git && \
    cd hemelb && \
    git checkout 5647f6d && \
    mkdir build && cd build

# Set working directory for subsequent build steps
WORKDIR /opt/hemelb/build

# First CMake run — will fail but download and prepare dependencies
RUN cmake -DCMAKE_C_COMPILER=/usr/bin/gcc-13 \
-DCMAKE_CXX_COMPILER=/usr/bin/g++-13 \
 .. || true

# Build only the ParMETIS external dependency
RUN make dep_ParMETIS

# OPTIONAL: Debug location of ParMETIS to verify build
RUN find . -name "libparmetis.a" && find . -name "parmetis.h"

# Re-run cmake now that ParMETIS is available, then build HemeLB
RUN cmake -DCMAKE_C_COMPILER=/usr/bin/gcc-13 \
-DCMAKE_CXX_COMPILER=/usr/bin/g++-13 \
 .. && make

# -------------------------
# Build geometry-tool and Python environment
# -------------------------
WORKDIR /opt/hemelb/geometry-tool
# Install the environment
RUN conda env create -f conda-environment.yml && \
        echo "source activate gmy-tool" >> ~/.bashrc && \
        bash -c "source activate gmy-tool && conda install --yes --file /opt/hemelb/hemelb-spec-2024-12-06.txt"
    

# -------------------------
# Install HemeLB python-tools and GUI geometry tool
# -------------------------
WORKDIR /opt/hemelb/python-tools
RUN conda run -n gmy-tool pip install . && \
    cd ../geometry-tool && \
    conda run -n gmy-tool pip install '.[gui]'

# -------------------------
# Install gevent for web 
# -------------------------
RUN apt-get update && apt-get install -y python3-pip && pip3 install gevent gevent-websocket

# -------------------------
# Provide data volume and working directory
# -------------------------
VOLUME /data
WORKDIR /data
