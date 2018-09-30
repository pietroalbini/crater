# This multi-stage Dockerfile is meant to be used with targets:
#
#   docker build --target server .
#   docker build --target agent .
#   docker build --target cli .
#
# Each target builds a Docker container specific for the wanted component of
# Crater, without extra stuff.

##########################################
## First stage: build the Crater binary ##
##########################################

FROM rust:slim-stretch AS build
WORKDIR /tmp/source/

# Install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libssl-dev pkg-config git

# Compile all the dependencies with a fake (and empty) crate
# This avoids rebuilding all the dependencies when Cargo.toml and Cargo.lock
# doesn't change
COPY Cargo.toml Cargo.lock docker/crater/dummy/ /tmp/source/
RUN cargo build --release

# Compile the proper Crater binary
COPY src /tmp/source/src
COPY templates /tmp/source/templates
COPY assets /tmp/source/assets
COPY .git /tmp/source/.git
COPY build.rs /tmp/source/build.rs
RUN find . -type f -name "*.rs" -exec touch {} \;
RUN cargo build --release

##########################################
## Second stage: generate a small image ##
##########################################

FROM debian:stretch-slim AS base
WORKDIR /opt/crater

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libssl-dev ca-certificates

COPY --from=build /tmp/source/target/release/crater /opt/crater/bin/crater
COPY local-crates/ /opt/crater/local-crates/
COPY config.toml /opt/crater/config.toml

ENV PATH "/opt/crater/bin:${PATH}"

################################################
## Third stage: fetch the docker .deb package ##
################################################

FROM debian:stretch-slim AS get_docker_deb

# Docker is installed in this weird way to avoid polluting the output image
# This stage fetches the latest .deb package from the Docker repository, and
# then the next steps installs it on the output image.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https gnupg2 curl
RUN echo 'deb [arch=amd64] https://download.docker.com/linux/debian stretch stable' >> /etc/apt/sources.list
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -d -odir::cache=/tmp docker-ce
RUN mv /tmp/archives/docker-ce_*.deb /tmp/docker-ce.deb

#####################################################
## Fourth stage: install Docker on the small image ##
#####################################################

FROM base AS base_docker

# This step just fetches the .deb package from the previous one and installs it
COPY --from=get_docker_deb /tmp/docker-ce.deb /tmp/docker-ce.deb
RUN dpkg -i /tmp/docker-ce.deb || DEBIAN_FRONTEND=noninteractive apt-get -f install -y && rm /tmp/docker-ce.deb

####################
## Target: server ##
####################

FROM base AS server

COPY docker/crater/run-server.sh /opt/crater/bin/run-crater-server

EXPOSE 80
CMD ["run-crater-server"]

###################
## Target: agent ##
###################

FROM base_docker AS agent

COPY docker/crater/run-agent.sh /opt/crater/bin/run-crater-agent

CMD ["run-crater-agent"]

#################
## Target: cli ##
#################

FROM base_docker AS cli
