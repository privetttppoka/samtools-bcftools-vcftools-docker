# Базовый образ
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV SOFT=/soft
ENV LD_LIBRARY_PATH=""
ENV PATH="$SOFT/samtools-br250520/bin:$SOFT/bcftools-br250520/bin:$SOFT/vcftools-br250520/bin:$PATH"
ENV SAMTOOLS="$SOFT/samtools-br250520/bin/samtools"
ENV BCFTOOLS="$SOFT/bcftools-br250520/bin/bcftools"
ENV VCFTOOLS="$SOFT/vcftools-br250520/bin/vcftools"

# Установка общих пакетов
# Установка общих пакетов + Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    wget \
    curl \
    git \
    ca-certificates \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libncurses5-dev \
    libncursesw5-dev \
    autoconf \
    automake \
    pkg-config \
    file \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Создание директории для ПО
RUN mkdir -p $SOFT

#libdeflate v1.24
RUN cd /tmp && \
    wget -O libdeflate-1.24.tar.gz https://github.com/ebiggers/libdeflate/archive/refs/tags/v1.24.tar.gz && \
    tar -xzf libdeflate-1.24.tar.gz && \
    rm libdeflate-1.24.tar.gz && \
    cd libdeflate-1.24 && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=$SOFT/libdeflate-br250520 -DLIBDEFLATE_BUILD_SHARED_LIB=ON && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/libdeflate-1.24

RUN ls -lh $SOFT/libdeflate-br250520/lib && file $SOFT/libdeflate-br250520/lib/*

# htslib v1.21
RUN cd /tmp && \
    wget -O htslib-1.21.tar.bz2 https://github.com/samtools/htslib/releases/download/1.21/htslib-1.21.tar.bz2 && \
    tar -xjf htslib-1.21.tar.bz2 && \
    rm htslib-1.21.tar.bz2 &&\
    cd htslib-1.21 && \
    CPPFLAGS="-I$SOFT/libdeflate-br250520/include" \
    LDFLAGS="-L$SOFT/libdeflate-br250520/lib" \
    ./configure --prefix=$SOFT/htslib-br250520 --with-libdeflate=$SOFT/libdeflate-br250520 && \
    make -j$(nproc) && make install && \
    # Проверка установки
    ls -l $SOFT/htslib-br250520/lib/libhts.so || (echo "ERROR: libhts.so not found!" && exit 1)

ENV LD_LIBRARY_PATH="/soft/htslib-br250520/lib:/soft/libdeflate-br250520/lib"


#samtools v1.21
RUN cd /tmp && \
    wget -O samtools-1.21.tar.bz2 https://github.com/samtools/samtools/releases/download/1.21/samtools-1.21.tar.bz2 && \
    tar -xjf samtools-1.21.tar.bz2 && \
    rm samtools-1.21.tar.bz2 &&\
    cd samtools-1.21 && \
    export CPPFLAGS="-I$SOFT/htslib-br250520/include -I$SOFT/libdeflate-br250520/include" && \
    export LDFLAGS="-L$SOFT/htslib-br250520/lib -L$SOFT/libdeflate-br250520/lib -Wl,-rpath,$SOFT/htslib-br250520/lib -Wl,-rpath,$SOFT/libdeflate-br240515/lib" && \
    export LIBS="-lhts -lz -lbz2 -llzma -lcurl -ldeflate" && \
    ./configure --prefix=$SOFT/samtools-br250520 --with-htslib=$SOFT/htslib-br250520 || (cat config.log && exit 1) && \
    make -j$(nproc) && make install &&\
    cd / && rm -rf /tmp/samtools-1.21

# bcftools v1.21 
RUN cd /tmp && \
    wget https://github.com/samtools/bcftools/releases/download/1.21/bcftools-1.21.tar.bz2 && \
    tar -xjf bcftools-1.21.tar.bz2 && \
    rm bcftools-1.21.tar.bz2 &&\
    cd bcftools-1.21 && \
    export CPPFLAGS="-I$SOFT/htslib-br250520/include -I$SOFT/libdeflate-br250520/include" && \
    export LDFLAGS="-L$SOFT/htslib-br250520/lib -L$SOFT/libdeflate-br250520/lib -Wl,-rpath,$SOFT/htslib-br250520/lib -Wl,-rpath,$SOFT/libdeflate-br240515/lib" && \
    export LIBS="-lhts -lz -lbz2 -llzma -lcurl -ldeflate" && \
    ./configure --prefix=$SOFT/bcftools-br250520 --with-htslib=/soft/htslib-src-br250520 || (cat config.log && exit 1) && \
    make -j$(nproc) && make install &&\
    cd / && rm -rf /tmp/bcftools-1.21

# vcftools v0.1.16 
RUN cd /tmp && \
    git clone https://github.com/vcftools/vcftools.git && \
    cd vcftools && \
    git checkout v0.1.16 && \
    ./autogen.sh && \
    ./configure --prefix=$SOFT/vcftools-br250520 && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/vcftools &&\
    cd / && rm -rf /tmp/vcftools

# Установка Python-библиотек
RUN pip3 install --no-cache-dir pysam

# Копирование Python-скрипта
COPY VCF_creator.py /app/VCF_creator.py

# Назначим рабочую директорию
WORKDIR /app
