[![epglv](epglv-logo.svg)](https://github.com/lapicidae/mariadb-epglv)

Slightly modified [MariaDB (latest)](https://hub.docker.com/_/mariadb?tab=tags) docker image with EPG2VDR Levenshtein distance support.


# [lapicidae/mariadb-epglv](https://github.com/lapicidae/mariadb-epglv)

[![GitHub Stars](https://img.shields.io/github/stars/lapicidae/mariadb-epglv.svg?color=3c0e7b&labelColor=555555&logoColor=ffffff&style=for-the-badge&logo=github)](https://github.com/lapicidae/mariadb-epglv)
[![Docker Pulls](https://img.shields.io/docker/pulls/lapicidae/mariadb-epglv.svg?color=3c0e7b&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=pulls&logo=docker)](https://hub.docker.com/r/lapicidae/mariadb-epglv)
[![Docker Stars](https://img.shields.io/docker/stars/lapicidae/mariadb-epglv.svg?color=3c0e7b&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=stars&logo=docker)](https://hub.docker.com/r/lapicidae/mariadb-epglv)
[![Build & Push](https://img.shields.io/github/workflow/status/lapicidae/mariadb-epglv/Docker%20Build%20&%20Push?label=Build%20%26%20Push&labelColor=555555&logoColor=ffffff&style=for-the-badge&logo=github)](https://github.com/lapicidae/mariadb-epglv/actions/workflows/docker.yml)


## Features

* regular and timely application updates
* integrated [epglv](https://projects.vdr-developer.org/git/vdr-epg-daemon.git/tree/epglv)
* recommended settings (deactivatable)
* creates [epgd database](root/docker-entrypoint-initdb.d/mysql-first-time.sql) automatically on first run

### *Note*
The image is automatically rebuilt when any of the following sources receive an update:

* [MariaDB](https://hub.docker.com/_/mariadb?tab=tags) Official Docker Image - latest
* [vdr-epg-daemon](https://projects.vdr-developer.org/git/vdr-epg-daemon.git) GitHub repository


## Getting Started
> :warning: **WARNING: If you migrate data from another MariaDB, please make a backup!**  
> We are not liable if data is lost or databases stop working.

**Please read the official [instructions](https://hub.docker.com/_/mariadb)!**


### Extra Parameters

EPGlv specific variables.

| Parameter | Function |
| :----: | --- |
| `-e LANG=en_US.UTF-8` | Default locale; see [list](https://sourceware.org/git/?p=glibc.git;a=blob_plain;f=localedata/SUPPORTED;hb=HEAD) (epglv seems to require initialized locales) |
| `-e TZ=Europe/London` | Optional - Specify timezone |
| `-e EPGD_RECOMMEND=false` | Optional - Disable recommended settings |


## Thanks

* **[VDR EPG Daemon Team](https://projects.vdr-developer.org/projects/vdr-epg-daemon)**
* **[MariaDB](https://mariadb.com/)**
