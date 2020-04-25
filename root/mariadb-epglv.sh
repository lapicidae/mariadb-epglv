#!/usr/bin/env bash

cnf="/etc/mysql/conf.d/mysqlepgd.cnf"

echo '
--------------------------------------------------------------
        __  __    __    ____  ____    __    ____  ____
       (  \/  )  /__\  (  _ \(_  _)  /__\  (  _ \(  _ \
        )    (  /(__)\  )   / _)(_  /(__)\  )(_) )) _ <
       (_/\/\_)(__)(__)(_)\_)(____)(__)(__)(____/(____/
                  ____  ____   ___  __  _  _
                 ( ___)(  _ \ / __)(  )( \/ )
                  )__)  )___/( (_-. )(__\  /
                 (____)(__)   \___/(____)\/

  https://projects.vdr-developer.org/projects/vdr-epg-daemon
--------------------------------------------------------------'
echo '
GID/UID
--------------------------------------------------------------'
echo "
User uid:    $(id -u mysql)
User gid:    $(id -g mysql)
--------------------------------------------------------------
"

if [ "$EPGD_RECOMMEND" = "yes" ]; then
	echo ">>>>>>>>>> pushing epgd recommend settings to $cnf <<<<<<<<<<"
	echo -e "[mysqld]\nlog_warnings=1\nmax_allowed_packet=128M\nwait_timeout=86400\nconnect_timeout=600\ninteractive_timeout=86400\nnet_read_timeout=600\nnet_write_timeout=180\ninnodb_lock_wait_timeout=100\ninnodb_rollback_on_timeout=1" > $cnf
else
	if [ -f "$cnf" ]; then
		rm -f $cnf
	fi
fi

exec /docker-entrypoint.sh "$@"
