# fesapi-docker

A simple centos 6.8 based Dockerfile that build fesapi and all its dependencies.

It also builds it's java wrapper and tests some basic java calls.

See : https://hub.docker.com/r/zz64/fesapi-docker  
See : https://github.com/F2I-Consulting/fesapi

## Build, test, retreive built lib
 
docker-compose -f docker-compose.yml build  
docker-compose -f docker-compose.yml up  
docker cp fesapi-container:/fesapiEnv/build  /libFesapiCpp.tar.gz .