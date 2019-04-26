#!/bin/bash

docker-compose -f docker-compose.yml build
docker-compose -f docker-compose.yml up
docker cp fesapi-container:/fesapiEnv/build/libFesapiCpp.tar.gz .
