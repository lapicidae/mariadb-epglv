[![epglv](epglv-logo.svg)](https://github.com/lapicidae/mariadb-epglv)

Slightly modified [MariaDB (latest)](https://hub.docker.com/_/mariadb?tab=tags) docker image with EPG2VDR Levenshtein distance support.


# [lapicidae/mariadb-epglv](https://github.com/lapicidae/mariadb-epglv)

[![GitHub Repo stars](https://img.shields.io/github/stars/lapicidae/mariadb-epglv?color=3c0e7b&logo=github&logoColor=fff&style=for-the-badge)](https://github.com/lapicidae/mariadb-epglv)
[![Docker Pulls](https://img.shields.io/docker/pulls/lapicidae/mariadb-epglv?color=3c0e7b&label=pulls&logo=docker&logoColor=fff&style=for-the-badge)](https://hub.docker.com/r/lapicidae/mariadb-epglv)
[![Docker Stars](https://img.shields.io/docker/stars/lapicidae/mariadb-epglv?color=3c0e7b&label=stars&logo=docker&logoColor=fff&style=for-the-badge)](https://hub.docker.com/r/lapicidae/mariadb-epglv)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/lapicidae/mariadb-epglv/docker.yml?logo=github&logoColor=ffffff&style=for-the-badge)](https://github.com/lapicidae/mariadb-epglv/actions/workflows/docker.yml)


## Features

* regular and timely application updates
* integrated [epglv](https://github.com/horchi/vdr-epg-daemon/tree/master/epglv)
* recommended settings (deactivatable)
* creates [epgd database](root/docker-entrypoint-initdb.d/mysql-first-time.sql) automatically on first run

### *Note*
The image is automatically rebuilt when any of the following sources receive an update:

* [MariaDB](https://hub.docker.com/_/mariadb?tab=tags) Official Docker Image - latest
* [vdr-epg-daemon](https://github.com/horchi/vdr-epg-daemon) GitHub repository


## Getting Started
> :warning: **WARNING: If you migrate data from another MariaDB, please make a backup!**  
> We are not liable if data is lost or databases stop working.

**Please read the official [instructions](https://hub.docker.com/_/mariadb)!**


### Extra Parameters

#### EPGlv specific variables:

| Parameter | Function |
|---|-----|
| `-e LANG=en_US.UTF-8` | Default locale; see [list](https://sourceware.org/git/?p=glibc.git;a=blob_plain;f=localedata/SUPPORTED;hb=HEAD) (epglv seems to require initialized locales) |
| `-e TZ=Europe/London` | Optional - Specify timezone |
| `-e EPGD_RECOMMEND=false` | Optional - Disable recommended settings |

#### Fine-tuning the recommended settings:
Can only be used if `EPGD_RECOMMEND=false` has **not** been set.

| Parameter | Default / Recommended Value | Function |
|-----|-----|-----|
| `RCMD_INNODB_BUFFER_POOL_SIZE` | Calculated automatically (30% of available RAM) | [MariaDB Knowledge Base](https://mariadb.com/kb/en/innodb-system-variables/#innodb_buffer_pool_size)
| `RCMD_INNODB_LOCK_WAIT_TIMEOUT` | 300 | [MariaDB Knowledge Base](https://mariadb.com/kb/en/innodb-system-variables/#innodb_lock_wait_timeout) |
| `RCMD_INNODB_ROLLBACK_ON_TIMEOUT` | 1 | [MariaDB Knowledge Base](https://mariadb.com/kb/en/innodb-system-variables/#innodb_rollback_on_timeout) |
| `RCMD_INNODB_USE_NATIVE_AIO` | 0 | [MariaDB Knowledge Base](https://mariadb.com/kb/en/innodb-system-variables/#innodb_use_native_aio) |
| `RCMD_TABLE_DEFINITION_CACHE` | 856 | [MariaDB Knowledge Base](https://mariadb.com/kb/en/server-system-variables/#table_definition_cache) |
| `RCMD_TRANSACTION_ISOLATION` | READ-COMMITTED | [MariaDB Knowledge Base](https://mariadb.com/kb/en/server-system-variables/#tx_isolation) |

#### Maintenance mode (**CAUTION!** Use only if you know what you are doing):

| Parameter | Default | Function |
|-----|-----|-----|
| `MAINT_INNODB_FORCE_RECOVERY`| 0 | [InnoDB Recovery Modes](https://mariadb.com/kb/en/innodb-recovery-modes/) |


## Thanks

* **[VDR EPG Daemon Team](https://github.com/horchi/vdr-epg-daemon)**
* **[MariaDB](https://mariadb.com/)**
