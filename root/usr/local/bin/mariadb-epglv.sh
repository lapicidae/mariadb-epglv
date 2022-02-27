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
	readarray -t LOCALE < <(locale -a 2>/dev/null)
	if [[ ! "${LOCALE[*]}" =~ "${LANG:0:6}" ]]; then	# use only first 6 letters of $LANG
		locale-gen en_US.UTF-8 "$LANG"
		update-locale LANG="$LANG" LANGUAGE="$(echo "$LANG" | cut -d "." -f 1):$(echo "$LANG" | cut -d "_" -f 1)"
	fi
fi


cnf="/etc/mysql/mariadb.conf.d/epglv.cnf"

## defaults
epglv_innodb_defragment=${RCMD_INNODB_DEFRAGMENT:-"1"}
epglv_innodb_lock_wait_timeout=${RCMD_INNODB_LOCK_WAIT_TIMEOUT:-"300"}
epglv_table_definition_cache=${RCMD_TABLE_DEFINITION_CACHE:-"500"}


## write config file
if [ "$EPGD_RECOMMEND" != "false" ]; then
	echo ">>>>>>>>>> pushing epgd recommend settings to $cnf <<<<<<<<<<"

	cat <<- EOF > $cnf
	[mariadb]
	innodb_defragment=$epglv_innodb_defragment
	innodb_lock_wait_timeout=$epglv_innodb_lock_wait_timeout
	table_definition_cache=$epglv_table_definition_cache
	EOF

	if [ -z "$RCMD_INNODB_BUFFER_POOL_SIZE" ]; then
		epglv_innodb_buffer_pool_size=$(awk '/^Mem/ {print($2*30/100);}' <(free --bytes))		# 30% of available RAM
		if [[ "$epglv_innodb_buffer_pool_size" =~ ^[0-9]+$ ]] && [ "$epglv_innodb_buffer_pool_size" -gt "134217728" ]; then	# if var is an integer and greater than the default value
			echo "innodb_buffer_pool_size=$epglv_innodb_buffer_pool_size" >> $cnf
		fi
	fi
else
	if [ -f "$cnf" ]; then
		rm -f $cnf
	fi
fi


## run default entrypoint
echo "Start MariaDB..."
exec /usr/local/bin/docker-entrypoint.sh "$@"
