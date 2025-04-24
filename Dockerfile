FROM dorowu/ubuntu-desktop-lxde-vnc:focal
LABEL MAINTAINER="Joyanta J. Mondal (joyanta@udel.edu)"
LABEL VERSION="2.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# -------------------------
# Install system dependencies
# -------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git sudo gnupg2 software-properties-common \
    build-essential cmake cmake-curses-gui \
    libopenmpi-dev openmpi-bin \
    libtinyxml-dev libboost-all-dev libcgal-dev \
    ca-certificates apt-transport-https lsb-release \
    xz-utils && \
    rm -rf /var/lib/apt/lists/*

# -------------------------
# Install Anaconda (Python 3.8.20)
# -------------------------
RUN wget https://repo.anaconda.com/archive/Anaconda3-2023.09-1-Linux-x86_64.sh -O anaconda.sh && \
    bash anaconda.sh -b -p $CONDA_DIR && \
    rm anaconda.sh && \
    $CONDA_DIR/bin/conda clean -afy

# -------------------------
# Fix Chrome GPG and install Chrome
# -------------------------
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# -------------------------
# Clone and build HemeLB
# -------------------------
WORKDIR /opt
RUN git clone https://github.com/lepotatoguy/hemelb.git && \
    cd hemelb && \
    git checkout 5647f6d && \
    mkdir build && cd build && \
    cmake .. && \
    make && \
    ln -s /opt/hemelb/build/hemelb /usr/local/bin/hemelb

# -------------------------
# Build geometry-tool and Python environment
# -------------------------
WORKDIR /opt/hemelb/Tools/geometry-tool
COPY hemelb-spec-2024-12-06.txt conda-environment.yml ./
RUN conda env create -f conda-environment.yml && \
    echo "source activate gmy-tool" >> ~/.bashrc && \
    conda run -n gmy-tool conda install --yes --file hemelb-spec-2024-12-06.txt

# -------------------------
# Install HemeLB python-tools and GUI geometry tool
# -------------------------
WORKDIR /opt/hemelb/Tools/python-tools
RUN conda run -n gmy-tool pip install . && \
    cd ../geometry-tool && \
    conda run -n gmy-tool pip install '.[gui]'

# -------------------------
# Environment setup
# -------------------------
ENV PATH="/opt/hemelb/Tools/geometry-tool:$PATH"
ENV PYTHONPATH="/opt/hemelb/Tools/python-tools:/opt/hemelb/Tools/geometry-tool:$PYTHONPATH"

# -------------------------
# Provide data volume and working directory
# -------------------------
VOLUME /data
WORKDIR /data
