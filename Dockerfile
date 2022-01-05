FROM mariadb:latest

WORKDIR /tmp

COPY root/ /

RUN sed -i 'H;1h;$!d;G' /etc/apt/sources.list.d/mariadb.list && \
    sed -i '2s/deb/deb-src/' /etc/apt/sources.list.d/mariadb.list && \
    apt-get update -qq && \
    apt-get install -qy apt-utils && \
    echo "**** install build packages ****" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qy \
      build-essential \
      git \
      libcrypto++-dev \
      libmariadb-dev \
      libmariadbd-dev \
      libssl-dev \
      python3-dev \
      zlib1g-dev && \
    if [ ! -e /usr/bin/python ]; then ln -sf $(which python3) /usr/bin/python ; fi && \
    if [ ! -e /usr/bin/python-config ]; then ln -sf $(which python3-config) /usr/bin/python-config ; fi && \
    echo "**** build epglv ****" && \
    cd /tmp && \
    git clone https://projects.vdr-developer.org/git/vdr-epg-daemon.git vdr-epg-daemon && \
    cp -a vdr-epg-daemon/scripts/. /usr/local/bin/ && \
    cd vdr-epg-daemon/epglv && \
      make all && \
      make install && \
    ln -s $(mysql_config --plugindir)/mysqlepglv.so /usr/lib/mysql/plugin/mysqlepglv.so && \
    echo "**** cleanup ****" && \
    apt-get remove -qy \
      apt-utils \
      build-essential \
      git \
      '*-dev' && \
    apt-get purge -qy --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/certs && \
    chmod 755 /usr/local/bin/mariadb-epglv.sh && \
    ln -s /usr/local/bin/mariadb-epglv.sh /mariadb-epglv.sh

ENV EPGD_RECOMMEND="true"

ENTRYPOINT ["/mariadb-epglv.sh"]
