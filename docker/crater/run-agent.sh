#!/bin/bash

if [[ ! -d "work" ]]; then
    echo "Error: you need to mount the 'work' directory in the container" 2>&1
    exit 1
fi

if [[ ! -S "/var/run/docker.sock" ]]; then
    echo "Error: you need to mount the docker socket in the container" >&1
    echo "The docker socket is /var/run/docker.sock" 2>&1
    exit 1
fi

if [[ -z "${CRATER_SERVER}" ]]; then
    echo "Error: missing environment variable CRATER_SERVER" 2>&1
    exit 1
fi

if [[ -z "${CRATER_TOKEN}" ]]; then
    echo "Error: missing environment variable CRATER_TOKEN" 2>&1
    exit 1
fi

if [[ -z "${CRATER_THREADS}" ]]; then
    echo "Error: missing environment variable CRATER_THREADS" 2>&1
    exit 1
fi

crater agent "${CRATER_SERVER}" "${CRATER_TOKEN}" --threads "${CRATER_THREADS}"
