#!/bin/bash

if [[ ! -d "work" ]]; then
    echo "Error: you need to mount the 'work' directory in the container"
    exit 1
fi

if [[ ! -f "tokens.toml" ]]; then
    echo "Error: you need to mount the 'tokens.toml' file in the container"
    exit 1
fi

crater server --bind 0.0.0.0:80
