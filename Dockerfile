FROM mariadb:latest

WORKDIR /tmp

RUN sed -i 'H;1h;$!d;G' /etc/apt/sources.list.d/mariadb.list &&\
    sed -i '2s/deb/deb-src/' /etc/apt/sources.list.d/mariadb.list && \
      \
    apt-get update -qq &&\
    apt-get install -qy apt-utils &&\
    #DEBIAN_FRONTEND=noninteractive apt-get upgrade -qy &&\
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
    cd vdr-epg-daemon/epglv && \
	  make all && \
	  make install && \
      \
    apt-get remove -qy \
	    apt-utils build-essential git \
		  libcrypto++-dev libssl-dev zlib1g-dev \
	    libmariadb-dev libmariadbd-dev libmariadb-dev-compat &&\
    apt-get purge -qy --auto-remove -o APT::AutoRemove::RecommendsImportant=false &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/ssl/certs


ENV LANG de_DE.UTF-8  
ENV LANGUAGE de_DE:de  
ENV LC_ALL de_DE.UTF-8

COPY mysqlepgd.cnf /etc/mysql/conf.d/
COPY mysql-first-time.sql /docker-entrypoint-initdb.d/
