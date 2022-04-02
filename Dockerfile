# Build Stage
FROM ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake clang

## Add source code to the build stage.
ADD . /mayhem-cmake-example
WORKDIR /mayhem-cmake-example

## TODO: ADD YOUR BUILD INSTRUCTIONS HERE.
RUN <Your Build Instructions>

# Package Stage
FROM ubuntu:20.04

## TODO: Change <Path in Builder Stage>
COPY --from=builder <Path in Builder Stage> /
