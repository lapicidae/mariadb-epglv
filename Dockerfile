FROM mariadb:latest

WORKDIR /tmp

COPY root/ /

ARG DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -qq && \
    echo "**** install build packages ****" && \
    apt-get install -qy \
      build-essential \
      git \
      libcrypto++-dev \
      libmariadb-dev \
      libmariadbd-dev \
      libssl-dev \
      python3-dev \
      zlib1g-dev && \
    if [ ! -e /usr/bin/python ]; then ln -sf $(which python3) /usr/bin/python ; fi && \
    echo "**** build epglv ****" && \
    cd /tmp && \
    git clone https://projects.vdr-developer.org/git/vdr-epg-daemon.git vdr-epg-daemon && \
    cp -a vdr-epg-daemon/scripts/. /usr/local/bin/ && \
    cd vdr-epg-daemon/epglv && \
    make all && \
    make install && \
    ln -s $(mariadb_config --plugindir)/mysqlepglv.so /usr/lib/mysql/plugin/mysqlepglv.so && \
    echo "**** cleanup ****" && \
    apt-get purge --auto-remove -qy \
      apt-utils \
      build-essential \
      git \
      '*-dev' && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    chmod 755 /usr/local/bin/mariadb-epglv.sh && \
    ln -s /usr/local/bin/mariadb-epglv.sh /mariadb-epglv.sh

ENTRYPOINT ["/mariadb-epglv.sh"]
