FROM centos:6.8

LABEL maintainer="camille.perin@protonmail.com"

RUN yum update -y \
	&& yum install -y \
	yum-plugin-ovl \
	epel-release
RUN yum update -y \
	&& yum install -y \
	automake \
	pcre-devel \
	git \
	gcc \
	gcc-c++ \
	make \
	byacc \
	java-1.8.0-openjdk-devel

WORKDIR fesapiEnv

#ENV MAKE_OPTS=-j12

ENV CFLAGS="-fPIC -O2"
ENV CXXFLAGS="-fPIC -O2"

WORKDIR /fesapiEnv/dependencies
ENV FES_INSTALL_DIR=/fesapiEnv/dependencies/install
RUN mkdir -p $FES_INSTALL_DIR
ENV PATH=$FES_INSTALL_DIR/bin:$PATH

WORKDIR /fesapiEnv/dependencies
#ADD util-linux-2.33.tar.gz .
ADD https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.33/util-linux-2.33.tar.gz .
RUN tar xf util-linux-2.33.tar.gz
WORKDIR util-linux-2.33
RUN ./configure --enable-static=yes --enable-shared=false --prefix=$FES_INSTALL_DIR
RUN make $MAKE_OPTS
RUN make install

WORKDIR /fesapiEnv/dependencies
ADD https://github.com/Kitware/CMake/releases/download/v3.14.1/cmake-3.14.1-Linux-x86_64.tar.gz .
RUN tar xf cmake-3.14.1-Linux-x86_64.tar.gz
#ADD cmake-3.14.1-Linux-x86_64.tar.gz .
ENV PATH=/fesapiEnv/dependencies/cmake-3.14.1-Linux-x86_64/bin:$PATH


WORKDIR /fesapiEnv/dependencies
RUN git clone https://github.com/madler/zlib.git
WORKDIR zlib
#RUN CFLAGS=-fPIC ./configure --static --prefix=$FES_INSTALL_DIR
#RUN CFLAGS="-fPIC -O2 -std=gnu99" ./configure --static --prefix=$FES_INSTALL_DIR
RUN ./configure --static --prefix=$FES_INSTALL_DIR
RUN make $MAKE_OPTS
RUN make install
#WORKDIR contrib/minizip
#RUN echo CFLAGS+= $CFLAGS >> Makefile
#RUN make

WORKDIR /fesapiEnv/dependencies
RUN git clone https://github.com/F2I-Consulting/Minizip.git
WORKDIR Minizip/build
RUN cmake -DZLIB_INCLUDE_DIR=$FES_INSTALL_DIR/include -DZLIB_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libz.a ../
RUN make
RUN make install

WORKDIR /fesapiEnv/dependencies
#ADD hdf5-1.8.21.tar.gz .
ADD https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.gz .
RUN tar xf hdf5-1.8.21.tar.gz
WORKDIR hdf5-1.8.21
#RUN ./configure --enable-static=yes --enable-shared=false --prefix=$FES_INSTALL_DIR
RUN ./configure --enable-static=yes --enable-shared=false --prefix=$FES_INSTALL_DIR --with-zlib=$FES_INSTALL_DIR
RUN make VERBOSE=ON $MAKE_OPTS
RUN make install

WORKDIR /fesapiEnv/dependencies
RUN git clone https://github.com/swig/swig.git
#ADD swig swig
WORKDIR swig
RUN ./autogen.sh
RUN ./configure --prefix=$FES_INSTALL_DIR
RUN make $MAKE_OPTS
RUN make install

WORKDIR /fesapiEnv
#RUN git clone https://github.com/F2I-Consulting/fesapi.git
RUN git clone https://github.com/camilleperin/fesapi.git
#ADD fesapi fesapi

WORKDIR build
RUN cmake \
 	-DHDF5_C_INCLUDE_DIR=$FES_INSTALL_DIR/include \
 	-DHDF5_C_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libhdf5.a \
 	# -DMINIZIP_INCLUDE_DIR=/usr/include/minizip \
 	# -DMINIZIP_LIBRARY_RELEASE=/usr/lib64/libminizip.so \
 	# -DMINIZIP_INCLUDE_DIR=../dependencies/zlib/contrib/minizip \
 	# -DMINIZIP_LIBRARY_RELEASE=../dependencies/zlib/contrib/minizip/minizip.o \
	# -DMINIZIP_LIBRARY_RELEASE=../dependencies/zlib/libz.a \
	# -DMINIZIP_LIBRARY_RELEASE=../dependencies/zlib/minizip.a \
	-DMINIZIP_INCLUDE_DIR=../dependencies/Minizip/build/install/include \
	-DMINIZIP_LIBRARY_RELEASE=../dependencies/Minizip/build/install/lib/libminizip.a \
 	# -DZLIB_INCLUDE_DIR=/usr/include \
 	# -DZLIB_LIBRARY_RELEASE=/usr/lib64/libz.so \
 	-DZLIB_INCLUDE_DIR=$FES_INSTALL_DIR/include \
 	-DZLIB_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libz.a \
 	# -DUUID_LIBRARY_RELEASE=/usr/lib64/libuuid.so \
 	-DUUID_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libuuid.a \
 	-DUNDER_DEV=FALSE \
	-DWITH_JAVA_WRAPPING=ON \
	-DWITH_EXAMPLES=ON \
 	-DCMAKE_BUILD_TYPE=Release \
 	../fesapi

RUN make VERBOSE=ON $MAKE_OPTS FesapiCpp
RUN make VERBOSE=ON $MAKE_OPTS
RUN make install
RUN tar cfz libFesapiCpp.tar.gz install

#WORKDIR /fesapiEnv
#RUN git clone https://github.com/camilleperin/fesapi-docker.git
#WORKDIR fesapi-docker/test/TestFesapi/src 
#RUN javac -cp /fesapiEnv/build/install/lib/fesapiJava-0.15.0.0.jar com/interactive/TestFesapi.java
#RUN java -Djava.library.path=/fesapiEnv/build/install/lib -cp /fesapiEnv/build/install/lib/fesapiJava-0.15.0.0.jar:. com.interactive.TestFesapi ../../TRAINING_1_1_1.epc

# #Retreive compiled file on the host
# #docker cp fervent_wright:/fesapiEnv/build/libFesapiCpp.tar.gz .
