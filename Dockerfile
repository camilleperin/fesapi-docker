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
RUN ./configure --enable-static=yes --enable-shared=false --disable-all-programs --enable-libuuid --prefix=$FES_INSTALL_DIR
RUN make $MAKE_OPTS
RUN make install

WORKDIR /fesapiEnv/dependencies
#ADD cmake-3.14.1-Linux-x86_64.tar.gz .
ADD https://github.com/Kitware/CMake/releases/download/v3.14.1/cmake-3.14.1-Linux-x86_64.tar.gz .
RUN tar xf cmake-3.14.1-Linux-x86_64.tar.gz
ENV PATH=/fesapiEnv/dependencies/cmake-3.14.1-Linux-x86_64/bin:$PATH


WORKDIR /fesapiEnv/dependencies
RUN git clone https://github.com/madler/zlib.git
WORKDIR zlib
RUN ./configure --static --prefix=$FES_INSTALL_DIR
RUN make $MAKE_OPTS
RUN make install

WORKDIR /fesapiEnv/dependencies
RUN git clone https://github.com/F2I-Consulting/Minizip.git
WORKDIR Minizip/build
RUN cmake -DZLIB_INCLUDE_DIR=$FES_INSTALL_DIR/include -DZLIB_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libz.a ../
RUN make
RUN make install

WORKDIR /fesapiEnv/dependencies
RUN git clone https://bitbucket.hdfgroup.org/scm/hdffv/hdf5.git
WORKDIR hdf5
RUN git checkout tags/hdf5-1_10_5
RUN ./configure --enable-static=yes --enable-shared=false --prefix=$FES_INSTALL_DIR --with-zlib=$FES_INSTALL_DIR
RUN make VERBOSE=ON $MAKE_OPTS
RUN make install

WORKDIR /fesapiEnv/dependencies
#ADD swig swig
RUN git clone https://github.com/swig/swig.git
WORKDIR swig
RUN ./autogen.sh
RUN ./configure --prefix=$FES_INSTALL_DIR
RUN make $MAKE_OPTS
RUN make install

WORKDIR /fesapiEnv
RUN git clone https://github.com/F2I-Consulting/fesapi.git
WORKDIR fesapi
RUN git fetch
RUN git pull
RUN git checkout tags/v0.16.0.0
WORKDIR /fesapiEnv/build
RUN cmake \
 	-DHDF5_C_INCLUDE_DIR=$FES_INSTALL_DIR/include \
 	-DHDF5_C_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libhdf5.a \
	-DMINIZIP_INCLUDE_DIR=../dependencies/Minizip/build/install/include \
	-DMINIZIP_LIBRARY_RELEASE=../dependencies/Minizip/build/install/lib/libminizip.a \
 	-DZLIB_INCLUDE_DIR=$FES_INSTALL_DIR/include \
 	-DZLIB_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libz.a \
 	-DUUID_LIBRARY_RELEASE=$FES_INSTALL_DIR/lib/libuuid.a \
 	-DUNDER_DEV=FALSE \
	-DWITH_JAVA_WRAPPING=ON \
	# -DWITH_EXAMPLES=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_FLAGS="" \
	-DCMAKE_CXX_FLAGS="" \
	-DCMAKE_CXX_FLAGS_RELEASE="-O1 -DNDEBUG" \
	-DCMAKE_C_FLAGS_RELEASE="-O1 -DNDEBUG" \
	-DHDF5_1_10=ON \
 	../fesapi

#RUN make VERBOSE=ON $MAKE_OPTS FesapiCpp
RUN make VERBOSE=ON $MAKE_OPTS
RUN make install
RUN tar cfz libFesapiCpp.tar.gz install

WORKDIR /fesapiEnv
RUN git clone https://github.com/camilleperin/fesapi-docker.git
WORKDIR fesapi-docker/test/TestFesapi/src 
RUN javac -cp `find /fesapiEnv/build/install -name fesapiJava*.jar` com/interactive/TestFesapi.java
RUN java -Djava.library.path=/fesapiEnv/build/install/lib64 -cp `find /fesapiEnv/build/install -name fesapiJava*.jar`:. com.interactive.TestFesapi ../../TRAINING_1_1_1.epc

# #Retreive compiled file on the host
# #docker cp fervent_wright:/fesapiEnv/build/libFesapiCpp.tar.gz .
