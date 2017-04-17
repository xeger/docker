# 1: Use ruby 2.3.3 as base:
FROM ruby:2.3.3

# 2: We'll set this gem path as the working directory
WORKDIR /usr/src/lib

# 3: We'll set the working dir as HOME and add the app's binaries path to $PATH:
ENV HOME=/usr/src/lib PATH=/usr/src/lib/bin:$PATH

# 4: Install docker - we'll need the client to run docker commands on the host engine, by mounting
# the host docker service's socket.
# Ripped off from https://hub.docker.com/_/docker Dockerfiles:
RUN set -ex && \
    export DOCKER_BUCKET=get.docker.com && \
    export DOCKER_VERSION=17.03.1-ce && \
    export DOCKER_SHA256=820d13b5699b5df63f7032c8517a5f118a44e2be548dd03271a86656a544af55 && \
    curl -fSL "https://${DOCKER_BUCKET}/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz && \
    echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - && \
    tar -xzvf docker.tgz && \
    mv docker/* /usr/local/bin/ && \
    rmdir docker && \
    rm docker.tgz

# 5: Install required gems:
ADD Gemfile docker.gemspec /usr/src/lib/
ADD lib/docker/version.rb /usr/src/lib/lib/docker/
RUN gem install guard && bundle install

# 6: Set the default command:
CMD ["guard"]
