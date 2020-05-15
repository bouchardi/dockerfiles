# Dockerfile with python 3.7, poetry0.12.12 and pytorch1.4
# --------------------------------------------------------
FROM nvidia/cuda:10.1-base-ubuntu16.04 as base

WORKDIR /app 

# Add the deadsnakes PPA to install more recent Python versions.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
        # Needed to install CUDA
        build-essential \
        # Needed to install `pip`
        curl \
        # Required to set the locale
        locales \
        # Required for add-apt-repository (below)
        software-properties-common \
        # Required for running without nvidia-docker
        cuda-command-line-tools-10-1 \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
        # Python 3.7
        python3.7 \
        python3.7-dev \
        python3.7-venv \
    && rm -rf /var/lib/apt/lists/*

# Setting the locale to UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Symlink required to run add-apt-repository after upgrading the Python version.
RUN ln -s /usr/lib/python3/dist-packages/apt_pkg.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3/dist-packages/apt_pkg.so

# Make python3.7 the default python executable
RUN ln -sf $(which python3.7) /usr/bin/python

# Install pip3.7
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py pip==19.3 && \
    rm get-pip.py

# Install Opencv dependencies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
 		libsm6 \
		libxext6 \
		libxrender-dev \
		libglib2.0-0

# Ensure that the poetry config is read from the right directory even
# when $HOME is overriden
ENV XDG_CONFIG_HOME /app/.config

# Install poetry
RUN pip install "poetry==0.12.17"

# Disable virtualenv creation to install our dependencies system-wide.
RUN poetry config settings.virtualenvs.create false
# Config file is not readable by other users by default
RUN chmod go+r $XDG_CONFIG_HOME/pypoetry/config.toml

COPY damage_map/__init__.py /app/damage_map
COPY pyproject.toml poetry.lock /app/

# Install python dependencies
RUN poetry install --no-interaction \
    # Poetry will try to read the auth file even if it is empty, so make
    # sure it is readable.
    && chmod go+r $XDG_CONFIG_HOME/pypoetry/auth.toml


COPY . /app
