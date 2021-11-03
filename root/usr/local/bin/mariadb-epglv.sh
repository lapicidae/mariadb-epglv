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
	cat <<- EOF > $cnf
	[mysqld]
	connect_timeout=$MARIADB_CONNECT_TIMEOUT
	innodb_defragment=$MARIADB_INNODB_DEFRAGMENT
	innodb_lock_wait_timeout=$MARIADB_INNODB_LOCK_WAIT_TIMEOUT
	innodb_rollback_on_timeout=$MARIADB_INNODB_ROLLBACK_ON_TIMEOUT
	interactive_timeout=$MARIADB_INTERACTIVE_TIMEOUT
	log_warnings=$MARIADB_LOG_WARNINGS
	max_allowed_packet=$MARIADB_MAX_ALLOWED_PACKET
	net_read_timeout=$MARIADB_NET_READ_TIMEOUT
	net_write_timeout=$MARIADB_NET_WRITE_TIMEOUT
	table_definition_cache = $MARIADB_TABLE_DEFINITION_CACHE
	table_open_cache = $MARIADB_TABLE_OPEN_CACHE
	transaction-isolation=$MARIADB_TRANSACTION_ISOLATION
	wait_timeout=$MARIADB_WAIT_TIMEOUT
	EOF
else
	if [ -f "$cnf" ]; then
		rm -f $cnf
	fi
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
