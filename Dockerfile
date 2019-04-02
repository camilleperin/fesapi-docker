FROM centos:7

LABEL maintainer="camille.perin@protonmail.com"

RUN yum update -y \
	&& yum install -y \
	git \
	gcc \
	gcc-c++ \
	make \
	libuuid-devel \
	minizip-devel \
	swig3 \
	wget

WORKDIR fesapiEnv

RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN rpm -ivh epel-release-latest-7.noarch.rpm
RUN yum install -y \
	cmake3 \
	hdf5-devel \

RUN mkdir build
RUN git clone https://github.com/F2I-Consulting/fesapi.git

RUN yum install -y wget

WORKDIR dependencies

#RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/bin/hdf5-1.8.21-Std-centos7-x86_64-shared_64.tar.gz
#RUN tar xf hdf5-1.8.21-Std-centos7-x86_64-shared_64.tar.gz

WORKDIR /fesapiEnv/dependencies
RUN git clone https://github.com/madler/zlib.git
WORKDIR zlib
RUN ./configure
RUN make
WORKDIR contrib/minizip
RUN make

#WORKDIR /fesapiEnv/dependencies
#RUN wget https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.33/util-linux-2.33.tar.gz
#RUN tar xf util-linux-2.33.tar.gz
#WORKDIR util-linux-2.33
#RUN ./configure
#RUN make

#WORKDIR /fesapiEnv/dependencies
#RUN wget https://github.com/Kitware/CMake/releases/download/v3.14.0/cmake-3.14.0.tar.gz
#RUN tar xf cmake-3.14.0.tar.gz
#WORKDIR cmake-3.14.0
#RUN ./bootstrap
#RUN make -j 8
#RUN make install

#WORKDIR /fesapiEnv/dependencies
#RUN wget http://prdownloads.sourceforge.net/swig/swig-3.0.12.tar.gz
#RUN tar xf swig-3.0.12.tar.gz

WORKDIR /fesapiEnv/build
RUN cmake3 \
	# -DHDF5_C_INCLUDE_DIR=../dependencies/hdf5/include \
	# -DHDF5_C_LIBRARY_RELEASE=../dependencies/hdf5/lib/libhdf5.so \
	-DHDF5_C_INCLUDE_DIR=/usr/include \
	-DHDF5_C_LIBRARY_RELEASE=/usr/lib64/libhdf5.so \
	-DMINIZIP_INCLUDE_DIR=/usr/include \
	-DMINIZIP_INCLUDE_DIR=../dependencies/zlib/contrib/minizip \
	# -DMINIZIP_LIBRARY_RELEASE=../dependencies/zlib/contrib/minizip/minizip.o \
	-DMINIZIP_LIBRARY_RELEASE=/usr/lib64/libminizip.so \
	-DZLIB_INCLUDE_DIR=../dependencies/zlib \
	# -DZLIB_LIBRARY_RELEASE=../dependencies/zlib/libz.a \
	-DZLIB_LIBRARY_RELEASE=/usr/lib64/libz.so \
	-DUUID_LIBRARY_RELEASE=/usr/lib64/libuuid.so \
	-DCMAKE_BUILD_TYPE=Release \
	../fesapi

#RUN make -k
