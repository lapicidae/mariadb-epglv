#!/bin/sh

cnf="/etc/mysql/conf.d/mysqlepgd.cnf"

if [ "$EPGD_RECOMMEND" = "yes" ]; then
	echo -e "[mysqld]\nmax_allowed_packet=128M\nwait_timeout=86400\nconnect_timeout=600\ninteractive_timeout=86400\nnet_read_timeout=600\nnet_write_timeout=180\ninnodb_lock_wait_timeout=100\ninnodb_rollback_on_timeout=1" > $cnf
else
	if [ -f "$cnf" ]; then
		rm -f $cnf
	fi
fi

exit 0
