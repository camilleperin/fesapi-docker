FROM centos:7

LABEL maintainer="camille.perin@protonmail.com"

RUN yum update -y \
	&& yum install -y \
	git \
	gcc \
	gcc-c++ \
	make \
	# libuuid-devel \
	# minizip-devel \
	swig3

WORKDIR fesapiEnv

#ADD http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm .
ADD epel-release-latest-7.noarch.rpm .
RUN rpm -ivh epel-release-latest-7.noarch.rpm
RUN yum install -y \
	cmake3

#ADD http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#RUN rpm -ivh epel-release-6-8.noarch.rpm
#RUN yum install -y \
#	cmake3

#WORKDIR dependencies
#RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/bin/hdf5-1.8.21-Std-centos7-x86_64-shared_64.tar.gz
#RUN tar xf hdf5-1.8.21-Std-centos7-x86_64-shared_64.tar.gz

WORKDIR /fesapiEnv/dependencies
ENV FES_INSTALL_DIR=/fesapiEnv/dependencies/install
RUN mkdir -p $FES_INSTALL_DIR

WORKDIR /fesapiEnv/dependencies
RUN git clone https://github.com/madler/zlib.git
WORKDIR zlib
RUN CFLAGS=-fPIC ./configure --static --prefix=$FES_INSTALL_DIR
RUN make -j12
RUN make
WORKDIR contrib/minizip
RUN echo CFLAGS=-fPIC -O -I../.. >> Makefile
RUN make

#WORKDIR /fesapiEnv/dependencies/zlib
#RUN make install

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

WORKDIR /fesapiEnv/java
ADD jdk-8u202-linux-x64.tar.gz .
ENV JAVA_HOME=/fesapiEnv/java/jdk1.8.0_202
#ENV PATH=/fesapiEnv/java/jdk-8u202-linux-x64/bin:$PATH

WORKDIR /fesapiEnv/dependencies
ADD hdf5-1.8.21.tar.gz .
#ADD https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.gz .
#RUN tar xf hdf5-1.10.5.tar.gz
WORKDIR hdf5-1.8.21
#RUN ./configure --enable-static=yes --enable-shared=false --prefix=$FES_INSTALL_DIR
RUN CFLAGS=-fPIC ./configure --enable-static=yes --enable-shared=false --prefix=$FES_INSTALL_DIR
RUN make VERBOSE=ON -j 12
RUN make install


WORKDIR /fesapiEnv/dependencies
ADD util-linux-2.33.tar.gz .
#RUN wget https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.33/util-linux-2.33.tar.gz
#RUN tar xf util-linux-2.33.tar.gz
WORKDIR util-linux-2.33
RUN CFLAGS=-fPIC ./configure --enable-static=yes --enable-shared=false --prefix=$FES_INSTALL_DIR
RUN make -j12
RUN make install


WORKDIR /fesapiEnv
#RUN git clone https://github.com/F2I-Consulting/fesapi.git
RUN git clone https://github.com/camilleperin/fesapi.git
WORKDIR build
RUN cmake3 \
	-DHDF5_C_INCLUDE_DIR=$FES_INSTALL_DIR/include \
	-DHDF5_C_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libhdf5.a \
	# -DMINIZIP_INCLUDE_DIR=/usr/include/minizip \
	# -DMINIZIP_LIBRARY_RELEASE=/usr/lib64/libminizip.so \
	-DMINIZIP_INCLUDE_DIR=../dependencies/zlib/contrib/minizip \
	# -DMINIZIP_LIBRARY_RELEASE=../dependencies/zlib/contrib/minizip/minizip.o \
	-DMINIZIP_LIBRARY_RELEASE=../dependencies/zlib/libz.a \
	# -DZLIB_INCLUDE_DIR=/usr/include \
	# -DZLIB_LIBRARY_RELEASE=/usr/lib64/libz.so \
	-DZLIB_INCLUDE_DIR=../dependencies/zlib \
	-DZLIB_LIBRARY_RELEASE=../dependencies/zlib/libz.a \
	# -DUUID_LIBRARY_RELEASE=/usr/lib64/libuuid.so \
	-DUUID_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libuuid.a \
	-DUNDER_DEV=FALSE \
	#-DWITH_JAVA_WRAPPING=ON \
	-DCMAKE_BUILD_TYPE=Release \
	../fesapi
RUN make VERBOSE=ON -j12
RUN make install
