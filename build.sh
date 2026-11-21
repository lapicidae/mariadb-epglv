#!/bin/bash

baseIMAGE=${baseIMAGE:-"mariadb"}
baseTAG=${baseTAG:-"${1:-latest}"}
imageTag=${imageTag:-"mariadb-epglv"}
EPGD_DEV=${EPGD_DEV:-"false"}

imageREPO='https://github.com/lapicidae/mariadb-epglv.git'
epgdREPO='https://github.com/horchi/vdr-epg-daemon.git'
epgdHISTORY='https://raw.githubusercontent.com/horchi/vdr-epg-daemon/master/HISTORY.h'

_history_ver() {
    awk -F'"' '/^#define[[:space:]]+_VERSION/ {print $2; exit}' "$@"
}

if [ "$EPGD_DEV" = 'true' ]; then
    gitDIR=$(mktemp -d --suffix '_epgdGIT')
    git clone --quiet "$epgdREPO" "$gitDIR"
    cd "$gitDIR" || exit 1

    ver="$(git describe --tags 2>/dev/null)"
    if [ -z "$ver" ] && [ -f HISTORY.h ]; then
        ver="$(_history_ver HISTORY.h)"
    fi
    printf -v epgdVersion '%s' "$ver"
    printf -v epgdRevision '%s' "$(git log --pretty=format:'%H' -n 1)"

    cd "$OLDPWD" || exit 1
    rm -rf "$gitDIR"
else
    remoteTags="$(git ls-remote --tags --sort=-version:refname --refs "$epgdREPO")"
    latestUpstream="$(printf '%s\n' "$remoteTags" | head -n 1 | cut -d/ -f3)"
    if [ -z "$latestUpstream" ]; then
        latestUpstream="$(curl -fsSL "$epgdHISTORY" | _history_ver)"
    fi
    matchLine=''
    if [ -n "$latestUpstream" ]; then
        matchLine="$(printf '%s\n' "$remoteTags" | awk -v tag="$latestUpstream" '$2 == "refs/tags/" tag {print $1 "\t" $2; exit}')"
    fi
    if [ -n "$matchLine" ]; then
        epgdRevision="${matchLine%%$'\t'*}"
        epgdVersion="${matchLine##*/}"
    else
        epgdVersion="${latestUpstream:-unknown}"
        epgdRevision="$(git ls-remote "$epgdREPO" HEAD | cut -f 1)"
    fi
fi

if [ -d "$( dirname -- "$( readlink -f -- "$0" )" )/.git" ]; then
    printf -v imageRevision '%s' "$(git rev-parse HEAD)"
else
    printf -v imageRevision '%s' "$(git ls-remote "${imageREPO}" refs/heads/master | cut -f 1)"
fi

dateTime="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
printf -v baseDIGEST '%s' "$(docker buildx imagetools inspect --format '{{.Manifest.Digest}}' "${baseIMAGE}:${baseTAG}")"

if [ "$baseIMAGE" = 'alpine' ]; then
    printf -v mariadbVersion '%s' "$(docker run --rm --pull=always "${baseIMAGE}:${baseTAG}" sh -c "apk update --quiet && apk info mariadb | head -n 1 | cut -d '-' -f 2 | tr -d '\n'")"
else
    printf -v mariadbVersion '%s' "$(docker run --rm --pull=always "${baseIMAGE}:${baseTAG}" sh -c "mariadbd --version | cut -d ' ' -f4 | cut -d '-' -f 1")"
fi

if [ "$EPGD_DEV" = 'true' ]; then
    dockerTAGS=(--tag "${imageTag}:dev")
else
    cleanVer="${mariadbVersion#v}"
    IFS='.' read -r vMajor vMinorPart _ <<< "$cleanVer"
    vMinor="${vMajor}.${vMinorPart}"
    vPatch="${cleanVer}"

    tagPrefix=''
    if [ "$baseIMAGE" = 'alpine' ]; then
        tagPrefix='alpine-'
    fi

    dockerTAGS=(
        --tag "${imageTag}:${tagPrefix}${vMajor}"
        --tag "${imageTag}:${tagPrefix}${vMinor}"
        --tag "${imageTag}:${tagPrefix}${vPatch}"
    )

    if [ "$baseIMAGE" = 'alpine' ]; then
        dockerTAGS+=(--tag "${imageTag}:alpine")
    elif [ "$baseTAG" = 'lts' ]; then
        dockerTAGS+=(--tag "${imageTag}:lts")
    else
        highestVersion="$(
            {
                printf '%s\n' "${vPatch}"
                docker image ls "${imageTag}" --format '{{.Tag}}' 2>/dev/null | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' || true
            } | sort -uV | tail -n 1
        )"
        if [ "$vPatch" = "$highestVersion" ]; then
            dockerTAGS+=(
                --tag "${imageTag}:mariadb"
                --tag "${imageTag}:latest"
            )
        fi
    fi
fi

docker build \
    --progress=plain \
    "${dockerTAGS[@]}" \
    --build-arg baseIMAGE="${baseIMAGE}" \
    --build-arg baseTAG="${baseTAG}" \
    --build-arg baseDIGEST="${baseDIGEST}" \
    --build-arg dateTime="${dateTime}" \
    --build-arg imageRevision="${imageRevision}" \
    --build-arg epgdRevision="${epgdRevision}" \
    --build-arg epgdVersion="${epgdVersion}" \
    --build-arg mariadbVersion="${mariadbVersion}" \
    --build-arg EPGD_DEV="${EPGD_DEV}" \
    .
