ARG VERSION_TAG=latest
FROM mariadb:${VERSION_TAG}

WORKDIR /tmp

COPY root/ /

ENV LANG="en_US.UTF-8"

ARG EPGD_DEV="false" \
    DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -qq && \
    echo "**** install build packages ****" && \
    apt-get install -qy \
      build-essential \
      git \
      libcrypto++-dev \
      libmariadb-dev \
      libmariadbd-dev \
      libssl-dev \
      locales \
      python3-dev \
      zlib1g-dev && \
    if [ ! -e /usr/bin/python ]; then ln -sf $(which python3) /usr/bin/python ; fi && \
    echo "**** init locales ****" && \
    localedef -i $(echo "$LANG" | cut -d "." -f 1) -c -f $(echo "$LANG" | cut -d "." -f 2) -A /usr/share/locale/locale.alias $LANG && \
    locale-gen de_DE.UTF-8 $LANG && \
    update-locale LANG="$LANG" LANGUAGE="$(echo "$LANG" | cut -d "." -f 1):$(echo "$LANG" | cut -d "_" -f 1)" && \
    echo "**** build epglv ****" && \
    cd /tmp && \
    epgdREPO='https://github.com/horchi/vdr-epg-daemon.git' && \
    [ "$EPGD_DEV" = 'true' ] && \
    git clone "$epgdREPO" vdr-epg-daemon || \
    git -c advice.detachedHead=false clone "$epgdREPO" --single-branch --branch $(git ls-remote --tags --sort=-version:refname --refs "$epgdREPO" | head -n 1 | cut -d/ -f3) vdr-epg-daemon && \
    cd vdr-epg-daemon/epglv && \
    sed -i "s/^MYSQL_PLGDIR :=.*/MYSQL_PLGDIR := \/usr\/lib\/mysql\/plugin/g" Makefile && \
    make all && \
    make install && \
    echo "**** epgd scripts ****" && \
    cp -a /tmp/vdr-epg-daemon/scripts/. /usr/local/bin/ && \
    echo "**** cleanup ****" && \
    apt-get purge --auto-remove -qy \
      apt-utils \
      build-essential \
      git && \
    dpkg -l | grep "\-dev" | sed 's/ \+ /|/g' | cut -d '|' -f 2 | cut -d ':' -f 1 | xargs apt-get purge --auto-remove -qy && \
    apt-get clean && \
    rm -rf \
      /var/lib/apt/lists/* \
      /tmp/* \
      /var/tmp/* && \
    if [ -L /usr/bin/python ]; then unlink /usr/bin/python ; fi && \
    chmod 755 /usr/local/bin/mariadb-epglv.sh && \
    ln -s /usr/local/bin/mariadb-epglv.sh /mariadb-epglv.sh

ENTRYPOINT ["/mariadb-epglv.sh", "mariadbd"]
