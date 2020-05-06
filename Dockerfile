FROM mariadb:latest

WORKDIR /tmp

COPY root/ /

RUN sed -i 'H;1h;$!d;G' /etc/apt/sources.list.d/mariadb.list && \
    sed -i '2s/deb/deb-src/' /etc/apt/sources.list.d/mariadb.list && \
      \
    apt-get update -qq && \
    apt-get install -qy apt-utils && \
    #DEBIAN_FRONTEND=noninteractive apt-get upgrade -qy && \
      \
    apt-get install -qy locales &&\
    echo "Europe/Berlin" > /etc/timezone &&\
    dpkg-reconfigure -f noninteractive tzdata &&\
    echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen; locale-gen && \
      \
    DEBIAN_FRONTEND=noninteractive apt-get install -qy build-essential git \
	    libmariadb-dev libmariadbd-dev libmariadb-dev-compat zlib1g-dev libcrypto++-dev libssl-dev && \
      \
    cd /tmp && \
    git clone https://projects.vdr-developer.org/git/vdr-epg-daemon.git vdr-epg-daemon && \
    cp -a vdr-epg-daemon/scripts/. /usr/local/bin/ && \
    cd vdr-epg-daemon/epglv && \
	  make all && \
	  make install && \
      \
    apt-get remove -qy \
	    apt-utils build-essential git \
		  libcrypto++-dev libssl-dev zlib1g-dev \
	    libmariadb-dev libmariadbd-dev libmariadb-dev-compat && \
    apt-get purge -qy --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/certs && \
    chmod 755 /mariadb-epglv.sh

ENV LANG="de_DE.UTF-8" \
    LANGUAGE="de_DE:de" \
    LC_ALL="de_DE.UTF-8" \
    EPGD_RECOMMEND="yes" \
    MARIADB_LOG_WARNINGS="1" \
    MARIADB_MAX_ALLOWED_PACKET="128M" \
    MARIADB_WAIT_TIMEOUT="86400" \
    MARIADB_CONNECT_TIMEOUT="600" \
    MARIADB_INTERACTIVE_TIMEOUT="86400" \
    MARIADB_NET_READ_TIMEOUT="600" \
    MARIADB_NET_WRITE_TIMEOUT="300" \
    MARIADB_INNODB_LOCK_WAIT_TIMEOUT="300" \
    MARIADB_INNODB_ROLLBACK_ON_TIMEOUT="1"

ENTRYPOINT ["/mariadb-epglv.sh"]
