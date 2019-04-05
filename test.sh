#!/bin/bash

docker build -t fesapi . && \
docker run --rm --interactive --tty fesapi bash
