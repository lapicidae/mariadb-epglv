#!/bin/bash

## exit when any command fails
set -e


## Ideally, change these variables via 'docker build-arg'
# e.g.: docker build --tag mariadb-epglv --build-arg EPGD_DEV=true .
inVM=${inVM:-"false"}
EPGD_DEV=${EPGD_DEV:-"false"}
epgdREPO=${epgdREPO:-"https://github.com/horchi/vdr-epg-daemon.git"}
epgdVersion=${epgdVersion:-"unknown"}
baseIMAGE=${baseIMAGE:-"alpine"}
baseTAG=${baseTAG:-"latest"}
LANG=${LANG:-"en_US.UTF-8"}


## Do not change!
LC_ALL="C"


## colored notifications
_ntfy() {
	printf '\e[36;1;2m**** %-6s ****\e[m\n' "$@"
}


## error messages before exiting
trap 'printf "\n\e[35;1;2m%s\e[m\n" "KILLED!"; exit 130' INT
trap 'printf "\n\e[31;1;2m> %s\nCommand terminated with exit code %s.\e[m\n" "$BASH_COMMAND" "$?"' ERR


## Profit!
_ntfy 'prepare'

if [ "$baseIMAGE" = 'alpine' ]; then
	runtimePKG=(
		coreutils
		findutils
		mariadb
		mariadb-backup
		mariadb-client
		mariadb-server-utils
		musl-locales
		pwgen
		socat
		tzdata
		zstd
	)
	buildPKG=(
		gcc
		git
		make
		mariadb-dev
		musl-dev
		python3-dev
	)

	installPKG="apk add --no-cache --upgrade"
	removePKG="apk del --no-cache"
	mariadbPLGDIR='/usr/lib/mariadb/plugin'

elif [ "$baseIMAGE" = 'mariadb' ]; then
	runtimePKG=(
		locales
	)
	buildPKG=(
		build-essential
		git
		libcrypto++-dev
		libmariadb-dev
		libmariadbd-dev
		libssl-dev
		python3-dev
		zlib1g-dev
	)

	export DEBIAN_FRONTEND="noninteractive"
	installPKG="apt-get install -qy"
	removePKG="apt-get purge -qy --auto-remove"
	mariadbPLGDIR='/usr/lib/mysql/plugin'
	_ntfy 'upgrade'
	apt-get update -qq
else
	printf '\e[31;1;2m!!! WRONG BASE IMAGE !!!\e[m\n'
	exit 1
fi



_ntfy 'install runtime packages'
$installPKG "${runtimePKG[@]}"

if [ "$baseIMAGE" = 'alpine' ]; then
	_ntfy 'install gosu'
	echo '@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> '/etc/apk/repositories'
	$installPKG gosu@testing
fi

_ntfy 'install build packages'
$installPKG "${buildPKG[@]}"

if [ "$baseIMAGE" = 'mariadb' ]; then
	_ntfy 'locale'
	localedef -i "$(echo "$LANG" | cut -d "." -f 1)" -c -f "$(echo "$LANG" | cut -d "." -f 2)" -A /usr/share/locale/locale.alias "$LANG"
	locale-gen "$LANG"
	update-locale LANG="$LANG" LANGUAGE="$(echo "$LANG" | cut -d "." -f 1):$(echo "$LANG" | cut -d "_" -f 1)"
fi

# _ntfy 'bash tweaks'
# {
#     printf '[ -r /usr/local/bin/contenv2env ] && . /usr/local/bin/contenv2env\n'
#     printf '[ -r /etc/bash.aliases ] && . /etc/bash.aliases\n'
# } >> /etc/bash.bashrc
# rm -rf /root/.bashrc

# _ntfy 'create epgd user'
# useradd --uid 911 --system --no-create-home --shell /bin/false epgd
# usermod -a -G users epgd

_ntfy 'folders and symlinks'
if [ "$baseIMAGE" = 'alpine' ]; then
	mkdir -p /var/lib/mysql/mysql
	touch /var/lib/mysql/mysql/user.frm
	rm -rf /var/lib/mysql
	mkdir -p /var/lib/mysql /run/mysqld
fi
ln -s /usr/local/bin/mariadb-epglv.sh /mariadb-epglv.sh

_ntfy "compile & install ${epgdVersion}"
cd /tmp || exit 1
if [ "$EPGD_DEV" = 'true' ]; then
	git clone "$epgdREPO" vdr-epg-daemon
else
	git -c advice.detachedHead=false clone "$epgdREPO" --single-branch --branch "$(git ls-remote --tags --sort=-version:refname --refs "$epgdREPO" | head -n 1 | cut -d/ -f3)" vdr-epg-daemon
fi
cd vdr-epg-daemon/epglv || exit 1
sed -i "s/^MYSQL_PLGDIR :=.*/MYSQL_PLGDIR := ${mariadbPLGDIR//\//\\/}/g" Makefile
make all
make install

_ntfy 'change permissions'
if [ "$baseIMAGE" = 'alpine' ]; then
	chown -R mysql:mysql /var/lib/mysql /run/mysqld
	chmod 1777 /run/mysqld
fi
chmod 755 /usr/local/bin/mariadb-epglv.sh

if [ "$baseIMAGE" = 'alpine' ]; then
	_ntfy 'workarounds'
	# comment out a few problematic configuration values
	find /etc/my* -name '*.cnf' -print0 \
		| xargs -0 grep -lE '^(bind-address|log|user\s)' \
		| xargs -0 -I {} bash -c 'sed -Ei "s/^(bind-address|log|user\s)/#&/" "{}"'
	# don't reverse lookup hostnames, they are usually another container
	printf "[mariadb]\nhost-cache-size=0\nskip-name-resolve\n" > /etc/my.cnf.d/05-skipcache.cnf
fi

# if [ "$baseIMAGE" = 'alpine' ]; then
# 	_ntfy 'configuration'
# 	sed -i '/\[client-server\]/a\socket = /run/mysqld/mysqld.sock' /etc/my.cnf
# fi

if [ "$baseIMAGE" = 'alpine' ]; then
	_ntfy 'entrypoint & healthcheck'
	wget -O /usr/local/bin/docker-entrypoint.sh https://github.com/MariaDB/mariadb-docker/raw/refs/heads/master/docker-entrypoint.sh
	chmod 755 /usr/local/bin/docker-entrypoint.sh
	wget -O /usr/local/bin/healthcheck.sh https://github.com/MariaDB/mariadb-docker/raw/refs/heads/master/healthcheck.sh
	chmod 755 /usr/local/bin/healthcheck.sh
fi

_ntfy 'cleanup'
$removePKG "${buildPKG[@]}"

if [ "$baseIMAGE" = 'alpine' ]; then
	rm -rf \
		/tmp/* \
		/var/tmp/* \
		/var/cache/apk/*
else
	apt-get clean
	rm -rf \
		/var/lib/apt/lists/* \
		/tmp/* \
		/var/tmp/*
fi

## Delete this script if it is running in a Docker container
if [ -f '/.dockerenv' ] || [ "$inVM" = 'true' ]; then
	_ntfy "delete this installer ($0)"
	rm -- "$0"
fi

_ntfy 'all done'
printf '\e[32;1;2m>>> DONE! <<<\e[m\n'
