#!/bin/bash

baseIMAGE=${baseIMAGE:-"mariadb"}
baseTAG=${baseTAG:-"latest"}
imageTag=${imageTag:-"mariadb-epglv"}
EPGD_DEV=${EPGD_DEV:-"false"}

imageREPO='https://github.com/lapicidae/mariadb-epglv.git'
epgdREPO='https://github.com/horchi/vdr-epg-daemon.git'


if [ "$EPGD_DEV" = 'true' ]; then
    gitDIR=$(mktemp -d --suffix '_epgdGIT')
    git clone --quiet "$epgdREPO" "$gitDIR"

    cd "$gitDIR" || exit 1
    printf -v epgdVersion '%s' "$(git describe --tags)"
    #printf -v epgdRevision '%s' "$(git log --pretty=format:'%H' -n 1)"

    cd "$OLDPWD" || exit 1
    rm -rf "$gitDIR"
else
    printf -v epgdVersion '%s' "$(git ls-remote --tags --sort=-version:refname --refs "$epgdREPO" | head -n 1 | cut -d/ -f3)"
    #printf -v epgdRevision '%s' "$(git ls-remote -t "${epgdREPO}" "${epgdVersion}" | cut -f 1)"
fi

if [ -d "$( dirname -- "$( readlink -f -- "$0" )" )/.git" ]; then
    printf -v imageRevision '%s' "$(git rev-parse "$(git rev-parse --abbrev-ref HEAD)")"
else
    printf -v imageRevision '%s' "$(git ls-remote ${imageREPO} refs/heads/master | cut -f 1)"
fi

printf -v dateTime '%(%Y-%m-%dT%H:%M:%S%z)T'
printf -v baseDIGEST '%s' "$(docker image pull "${baseIMAGE}":"${baseTAG}" | grep -i digest | cut -d ' ' -f 2)"

if [ "$baseIMAGE" = 'alpine' ]; then
    printf -v mariadbVersion '%s' "$(docker run --rm "${baseIMAGE}":"${baseTAG}" sh -c "apk update --quiet && apk info mariadb | head -n 1 | cut -d '-' -f 2 | tr -d '\n'")"
else
    printf -v mariadbVersion '%s' "$(docker run --rm "${baseIMAGE}":"${baseTAG}" sh -c "mariadbd --version | cut -d ' ' -f4 | cut -d '-' -f 1")"
fi

docker build \
    --progress=plain \
    --tag "${imageTag}" \
    --build-arg baseIMAGE="${baseIMAGE}" \
    --build-arg baseTAG="${baseTAG}" \
    --build-arg baseDIGEST="${baseDIGEST}" \
    --build-arg dateTime="${dateTime}" \
    --build-arg imageRevision="${imageRevision}" \
    --build-arg epgdVersion="${epgdVersion}" \
    --build-arg mariadbVersion="${mariadbVersion}" \
    --build-arg EPGD_DEV="${EPGD_DEV}" \
    .
