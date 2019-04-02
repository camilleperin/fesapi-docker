#!/bin/bash

docker build -t fesapi .
docker run --interactive --tty fesapi bash
