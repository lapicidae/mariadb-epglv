#!/usr/bin/env bash

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


## init locales
if [ ! -z "$LANG" ];then
	readarray -t LOCALE < <(locale -a)
	if [[ ! "${LOCALE[*]}" =~ "${LANG:0:6}" ]]; then	# use only first 6 letters of $LANG
		locale-gen en_US.UTF-8 "$LANG"
		update-locale LANG="$LANG" LANGUAGE="$(echo "$LANG" | cut -d "." -f 1):$(echo "$LANG" | cut -d "_" -f 1)"
	fi
fi


cnf="/etc/mysql/conf.d/mysqlepgd.cnf"

## defaults
epglv_connect_timeout=${RCMD_CONNECT_TIMEOUT:-"300"}
epglv_innodb_defragment=${RCMD_INNODB_DEFRAGMENT:-"1"}
epglv_innodb_lock_wait_timeout=${RCMD_INNODB_LOCK_WAIT_TIMEOUT:-"600"}
epglv_innodb_rollback_on_timeout=${RCMD_INNODB_ROLLBACK_ON_TIMEOUT:-"0"}
epglv_interactive_timeout=${RCMD_INTERACTIVE_TIMEOUT:-"86400"}
epglv_log_warnings=${RCMD_LOG_WARNINGS:-"2"}
epglv_max_allowed_packet=${RCMD_MAX_ALLOWED_PACKET:-"128M"}
epglv_net_read_timeout=${RCMD_NET_READ_TIMEOUT:-"600"}
epglv_net_write_timeout=${RCMD_NET_WRITE_TIMEOUT:-"300"}
epglv_table_definition_cache=${RCMD_TABLE_DEFINITION_CACHE:-"1200"}
epglv_table_open_cache=${RCMD_TABLE_OPEN_CACHE:-"1200"}
epglv_transaction_isolation=${RCMD_TRANSACTION_ISOLATION:-"READ-COMMITTED"}
epglv_wait_timeout=${RCMD_WAIT_TIMEOUT:-"86400"}


if [ "$EPGD_RECOMMEND" != "false" ]; then
	echo ">>>>>>>>>> pushing epgd recommend settings to $cnf <<<<<<<<<<"
	cat <<- EOF > $cnf
	[mariadb]
	connect_timeout=$epglv_connect_timeout
	innodb_defragment=$epglv_innodb_defragment
	innodb_lock_wait_timeout=$epglv_innodb_lock_wait_timeout
	innodb_rollback_on_timeout=$epglv_innodb_rollback_on_timeout
	interactive_timeout=$epglv_interactive_timeout
	log_warnings=$epglv_log_warnings
	max_allowed_packet=$epglv_max_allowed_packet
	net_read_timeout=$epglv_net_read_timeout
	net_write_timeout=$epglv_net_write_timeout
	table_definition_cache = $epglv_table_definition_cache
	table_open_cache = $epglv_table_open_cache
	transaction-isolation=$epglv_transaction_isolation
	wait_timeout=$epglv_wait_timeout
	EOF

	if [ -z "$RCMD_INNODB_BUFFER_POOL_SIZE" ]; then
		epglv_innodb_buffer_pool_size=$(awk '/^Mem/ {print($2*75/100);}' <(free --bytes))			# 75% of available RAM
		if [[ "$epglv_innodb_buffer_pool_size" =~ ^[0-9]+$ ]]; then	# if var is an integer
			echo "innodb_buffer_pool_size=$epglv_innodb_buffer_pool_size" >> $cnf
		fi
	fi
	if [ -z "$RCMD_INNODB_LOG_FILE_SIZE" ] && [ ! -z "$epglv_innodb_buffer_pool_size" ]; then
		epglv_innodb_log_file_size=$(awk '{print($1*25/100);}' <(echo $epglv_innodb_buffer_pool_size))		# 25% of buffer pool size
		if [[ "$epglv_innodb_log_file_size" =~ ^[0-9]+$ ]]; then	# if var is an integer
			echo "innodb_log_file_size=$epglv_innodb_log_file_size" >> $cnf
		fi
	fi
else
	if [ -f "$cnf" ]; then
		rm -f $cnf
	fi
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
