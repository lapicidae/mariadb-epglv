#!/usr/bin/env bash

echo '
╔════════════════════════════════════════════════════════════════╗
║         __  __    __    ____  ____    __    ____  ____         ║
║        (  \/  )  /__\  (  _ \(_  _)  /__\  (  _ \(  _ \        ║
║         )    (  /(__)\  )   / _)(_  /(__)\  )(_) )) _ <        ║
║        (_/\/\_)(__)(__)(_)\_)(____)(__)(__)(____/(____/        ║
║                   ____  ____   ___  __  _  _                   ║
║                  ( ___)(  _ \ / __)(  )( \/ )                  ║
║                   )__)  )___/( (_-. )(__\  /                   ║
║                  (____)(__)   \___/(____)\/                    ║
║                                                                ║
║         https://github.com/vdr-projects/vdr-epg-daemon         ║
╚════════════════════════════════════════════════════════════════╝
'



## init locales ##
if [ -n "$LANG" ];then
	readarray -t LOCALE < <(locale -a 2>/dev/null)
	if [[ ! "${LOCALE[*]}" =~ ${LANG:0:6} ]]; then	# use only first 6 letters of $LANG
		locale-gen de_DE.UTF-8 "$LANG"
		update-locale LANG="$LANG" LANGUAGE="$(echo "$LANG" | cut -d "." -f 1):$(echo "$LANG" | cut -d "_" -f 1)"
	fi
fi



## recommended configuration ##
cnf="/etc/mysql/mariadb.conf.d/epglv.cnf"

# defaults
epglv_innodb_defragment=${RCMD_INNODB_DEFRAGMENT:-"1"}
epglv_innodb_lock_wait_timeout=${RCMD_INNODB_LOCK_WAIT_TIMEOUT:-"300"}
epglv_innodb_rollback_on_timeout=${RCMD_INNODB_ROLLBACK_ON_TIMEOUT:-"1"}
epglv_innodb_use_native_aio=${RCMD_INNODB_USE_NATIVE_AIO:-"0"}
epglv_table_definition_cache=${RCMD_TABLE_DEFINITION_CACHE:-"856"}
epglv_transaction_isolation=${RCMD_TRANSACTION_ISOLATION:-"READ-COMMITTED"}

if [ "$EPGD_RECOMMEND" != "false" ]; then
	echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Recommend Settings ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
	printf "%-30s%s\n" "innodb_defragment:" "$epglv_innodb_defragment"
	printf "%-30s%s\n" "innodb_lock_wait_timeout:" "$epglv_innodb_lock_wait_timeout"
	printf "%-30s%s\n" "innodb_rollback_on_timeout:" "$epglv_innodb_rollback_on_timeout"
	printf "%-30s%s\n" "innodb_use_native_aio:" "$epglv_innodb_use_native_aio"
	printf "%-30s%s\n" "table_definition_cache:" "$epglv_table_definition_cache"
	printf "%-30s%s\n" "transaction_isolation:" "$epglv_transaction_isolation"

	# write config file
	cat <<- EOF > $cnf
	# ATTENTION: Changes in this file will be overwritten on restart
	[mariadb]
	innodb_defragment=$epglv_innodb_defragment
	innodb_lock_wait_timeout=$epglv_innodb_lock_wait_timeout
	innodb_rollback_on_timeout=$epglv_innodb_rollback_on_timeout
	innodb_use_native_aio=$epglv_innodb_use_native_aio
	table_definition_cache=$epglv_table_definition_cache
	transaction_isolation=$epglv_transaction_isolation
	EOF

	if [ -z "$RCMD_INNODB_BUFFER_POOL_SIZE" ]; then
		epglv_innodb_buffer_pool_size=$(awk '/^Mem/ {print int($2*30/100);}' <(free --bytes))		# 30% of available RAM
		if [[ "$epglv_innodb_buffer_pool_size" =~ ^[0-9]+$ ]] && [ "$epglv_innodb_buffer_pool_size" -gt "134217728" ]; then	# if var is an integer and greater than the default value
			echo "innodb_buffer_pool_size=$epglv_innodb_buffer_pool_size" >> $cnf
			printf "%-30s%s\n" "innodb_buffer_pool_size:" "$epglv_innodb_buffer_pool_size"
		fi
	fi

	echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
	echo "pushed epgd recommend settings to '$cnf'"
elif [ -f "$cnf" ]; then
	rm -f $cnf
fi



## maintenance mode ##
maint="/etc/mysql/mariadb.conf.d/epglv_maint.cnf"
maint_innodb_force_recovery=${MAINT_INNODB_FORCE_RECOVERY:-"0"}

if [[ "$maint_innodb_force_recovery" == ?([1-6]) ]]; then		# numeric and between 1 to 6
	echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ WARNING: Maintenance Mode Enabled ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
	printf "%-30s%s\n" "innodb_force_recovery:" "$maint_innodb_force_recovery"
	echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"

	cat <<- EOF > $maint
	# ATTENTION: Changes in this file will be overwritten on restart
	[mariadb]
	innodb_force_recovery=$maint_innodb_force_recovery
	EOF
	echo "pushed epgd maintenance settings to '$maint'"
elif [ -f "$maint" ]; then
	rm -f $maint
fi



## run default entrypoint ##
echo "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Start MariaDB ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄"
exec /usr/local/bin/docker-entrypoint.sh "$@"
