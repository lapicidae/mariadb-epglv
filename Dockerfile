FROM mariadb:latest

WORKDIR /tmp

COPY root/ /

RUN sed -i 'H;1h;$!d;G' /etc/apt/sources.list.d/mariadb.list && \
    sed -i '2s/deb/deb-src/' /etc/apt/sources.list.d/mariadb.list && \
    apt-get update -qq && \
    apt-get install -qy apt-utils && \
    echo "**** timezone and locale ****" && \
    apt-get install -qy locales &&\
    echo "Europe/Berlin" > /etc/timezone &&\
    dpkg-reconfigure -f noninteractive tzdata &&\
    echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen; locale-gen && \
    echo "**** install build packages ****" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qy \
      build-essential \
      git \
      libcrypto++-dev \
      libmariadb-dev \
      libmariadb-dev-compat \
      libmariadbd-dev \
      libssl-dev \
      python3-dev \
      zlib1g-dev && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    if [ ! -e /usr/bin/python-config ]; then ln -sf python3-config /usr/bin/python-config ; fi && \
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
      libcrypto++-dev \
      libmariadb-dev \
      libmariadb-dev-compat \
      libmariadbd-dev \
      libssl-dev \
      python3-dev \
      zlib1g-dev && \
    apt-get purge -qy --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/certs && \
    chmod 755 /usr/local/bin/mariadb-epglv.sh && \
    ln -s /usr/local/bin/mariadb-epglv.sh /mariadb-epglv.sh

ENV LANG="de_DE.UTF-8" \
    LANGUAGE="de_DE:de" \
    LC_ALL="de_DE.UTF-8" \
    EPGD_RECOMMEND="yes" \
    MARIADB_CONNECT_TIMEOUT="300" \
    MARIADB_INNODB_LOCK_WAIT_TIMEOUT="600" \
    MARIADB_INNODB_ROLLBACK_ON_TIMEOUT="0" \
    MARIADB_INTERACTIVE_TIMEOUT="86400" \
    MARIADB_LOG_WARNINGS="2" \
    MARIADB_MAX_ALLOWED_PACKET="128M" \
    MARIADB_NET_READ_TIMEOUT="600" \
    MARIADB_NET_WRITE_TIMEOUT="300" \
    MARIADB_TRANSACTION_ISOLATION="READ-COMMITTED" \
    MARIADB_WAIT_TIMEOUT="86400"

ENTRYPOINT ["/mariadb-epglv.sh"]
