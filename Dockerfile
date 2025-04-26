ARG baseIMAGE=mariadb \
    baseTAG=latest

FROM ${baseIMAGE}:${baseTAG}

COPY root/ /

ARG authors="A. Hemmerle <github.com/lapicidae>" \
    EPGD_DEV="true" \
    inVM="true" \
    baseDIGEST \
    baseIMAGE \
    baseTAG \
    dateTime \
    imageRevision \
    mariadbVersion

ENV LANG="en_US.UTF-8"

RUN if [ ${baseIMAGE} = 'alpine' ]; then \
      echo "**** install bash ****"; \
      apk add --no-cache --upgrade bash; \
    fi && \
    /bin/bash -c '/install.sh'

LABEL org.opencontainers.image.authors=${authors} \
      org.opencontainers.image.base.digest=${baseDIGEST} \
      org.opencontainers.image.base.name="docker.io/${baseIMAGE}:${baseTAG}" \
      org.opencontainers.image.created=${dateTime} \
      org.opencontainers.image.description="Slightly modified MariaDB with EPG2VDR Levenshtein distance support" \
      org.opencontainers.image.documentation="https://github.com/lapicidae/mariadb-epglv/blob/master/README.md" \
      org.opencontainers.image.licenses="GPL-2.0-only AND GPL-3.0-only AND GPL-3.0-or-later" \
      org.opencontainers.image.revision=${imageRevision} \
      org.opencontainers.image.source="https://github.com/lapicidae/mariadb-epglv/" \
      org.opencontainers.image.title="mariadb-epglv" \
      org.opencontainers.image.url="https://github.com/lapicidae/mariadb-epglv/blob/master/README.md" \
      org.opencontainers.image.version=${mariadbVersion}

VOLUME /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/mariadb-epglv.sh", "mariadbd"]
