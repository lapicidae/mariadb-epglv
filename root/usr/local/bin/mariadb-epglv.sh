#!/bin/bash
#
# Entrypoint wrapper for mariadb-epglv: prints the startup banner, initializes
# glibc locales, writes recommended/maintenance MariaDB config files, and hands
# off execution to the upstream MariaDB docker-entrypoint.sh.

readonly BANNER_WIDTH=64
readonly MIN_BUFFER_POOL_BYTES=134217728

ver='MariaDB unknown'
if [[ "$(mariadbd -V 2>/dev/null)" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
	ver="MariaDB ${BASH_REMATCH[1]}"
fi
pad=$(( (BANNER_WIDTH - ${#ver}) / 2 ))
ver_line="$(
	printf '║%*s%s%*s║' \
		"${pad}" '' "${ver}" "$(( BANNER_WIDTH - ${#ver} - pad ))" ''
)"

printf '%s\n' \
	'' \
	'╔════════════════════════════════════════════════════════════════╗' \
	'║         __  __    __    ____  ____    __    ____  ____         ║' \
	'║        (  \/  )  /__\  (  _ \(_  _)  /__\  (  _ \(  _ \        ║' \
	'║         )    (  /(__)\  )   / _)(_  /(__)\  )(_) )) _ <        ║' \
	'║        (_/\/\_)(__)(__)(_)\_)(____)(__)(__)(____/(____/        ║' \
	'║                   ____  ____   ___  __  _  _                   ║' \
	'║                  ( ___)(  _ \ / __)(  )( \/ )                  ║' \
	'║                   )__)  )___/( (_-. )(__\  /                   ║' \
	'║                  (____)(__)   \___/(____)\/                    ║' \
	'║                                                                ║' \
	'╟────────────────────────────────────────────────────────────────╢' \
	"${ver_line}" \
	'║            https://github.com/horchi/vdr-epg-daemon            ║' \
	'╚════════════════════════════════════════════════════════════════╝' \
	''

## detect OS & config dir ##
is_alpine='false'
cnf_dir='/etc/mysql/mariadb.conf.d'
if grep -qE '^ID="?alpine"?' /etc/os-release 2>/dev/null; then
	is_alpine='true'
	cnf_dir='/etc/my.cnf.d'
fi

## init locales ##
if [[ "${is_alpine}" != 'true' && -n "${LANG}" ]]; then
	readarray -t locales < <(locale -a 2>/dev/null)
	# Match only the first 6 characters of $LANG (e.g. "de_DE." / "en_US.").
	if [[ "${locales[*]}" != *"${LANG:0:6}"* ]]; then
		locale-gen de_DE.UTF-8 "${LANG}"
		update-locale LANG="${LANG}" LANGUAGE="${LANG%%.*}:${LANG%%_*}"
	fi
fi

## recommended configuration ##
cnf="${cnf_dir}/epglv.cnf"

if [[ "${EPGD_RECOMMEND}" != 'false' ]]; then
	settings=()

	buffer_pool_size="${RCMD_INNODB_BUFFER_POOL_SIZE}"
	if [[ -z "${buffer_pool_size}" ]]; then
		mem_bytes=''
		if [[ -r /sys/fs/cgroup/memory.max ]]; then
			mem_bytes="$(< /sys/fs/cgroup/memory.max)"
		fi
		if [[ ! "${mem_bytes}" =~ ^[0-9]+$ && -r /proc/meminfo ]]; then
			mem_bytes="$(
				awk '/^MemTotal:/ {print $2 * 1024; exit}' /proc/meminfo
			)"
		fi
		if [[ "${mem_bytes}" =~ ^[0-9]+$ ]] \
			&& (( mem_bytes / 2 > MIN_BUFFER_POOL_BYTES )); then
			buffer_pool_size="$(( mem_bytes / 2 ))"
		fi
	fi
	if [[ -n "${buffer_pool_size}" ]]; then
		settings+=("innodb_buffer_pool_size=${buffer_pool_size}")
	fi

	settings+=(
		"innodb_lock_wait_timeout=${RCMD_INNODB_LOCK_WAIT_TIMEOUT:-300}"
		"innodb_rollback_on_timeout=${RCMD_INNODB_ROLLBACK_ON_TIMEOUT:-1}"
		"loose_innodb_snapshot_isolation=${RCMD_INNODB_SNAPSHOT_ISOLATION:-0}"
		"innodb_use_native_aio=${RCMD_INNODB_USE_NATIVE_AIO:-0}"
		"table_definition_cache=${RCMD_TABLE_DEFINITION_CACHE:-856}"
		"transaction_isolation=${RCMD_TRANSACTION_ISOLATION:-READ-COMMITTED}"
	)

	printf '%s\n' '┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Recommend Settings ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄'
	printf '%s\n' \
		'# ATTENTION: Changes in this file will be overwritten on restart' \
		'[mariadb]' > "${cnf}"
	for entry in "${settings[@]}"; do
		key="${entry%%=*}"
		val="${entry#*=}"
		printf '%s=%s\n' "${key}" "${val}" >> "${cnf}"
		printf '%-30s%s\n' "${key#loose_}:" "${val}"
	done
	printf '%s\n' \
		'┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄' \
		"pushed epgd recommend settings to '${cnf}'"
elif [[ -f "${cnf}" ]]; then
	rm -f "${cnf}"
fi

## maintenance mode ##
maint="${cnf_dir}/epglv_maint.cnf"
maint_innodb_force_recovery="${MAINT_INNODB_FORCE_RECOVERY:-0}"

if [[ "${maint_innodb_force_recovery}" =~ ^[1-6]$ ]]; then
	printf '%s\n' '┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ WARNING: Maintenance Mode Enabled ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄'
	printf '%-30s%s\n' 'innodb_force_recovery:' "${maint_innodb_force_recovery}"
	printf '%s\n' \
		'# ATTENTION: Changes in this file will be overwritten on restart' \
		'[mariadb]' \
		"innodb_force_recovery=${maint_innodb_force_recovery}" > "${maint}"
	printf '%s\n' \
		'┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄' \
		"pushed epgd maintenance settings to '${maint}'"
elif [[ -f "${maint}" ]]; then
	rm -f "${maint}"
fi

## run default entrypoint ##
printf '%s\n' '┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Start MariaDB ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄'
exec /usr/local/bin/docker-entrypoint.sh "$@"
