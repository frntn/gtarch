#!/bin/bash

set +x
set -u

function next_page {
    cd $DSTFOLDER 
    curl -H "Accept-Encoding: gzip" -s "http://$BASEURI/${BEFORE#/}" \
        | gunzip  \
        | grep -E "hover" \
        | grep href \
        | sed -E 's,.*href="([^""]*)".*,\1,' \
        | sed -E 's,^(http://[^/]*/[^/]*/[0-9]*).*,\1,' \
        | sed 's,post,image,' \
        | xargs curl -s \
        | grep "content-image" \
        | sed -E 's,.*data-src="([^""]*)".*,\1,' \
        | wget -nc -q -i - &
    cd - >/dev/null
}

BASEFOLDER="$(dirname $0)"
BASENAME="$(basename $0)"
BEFORE="/archive?before_time=$(date +%s)"
SAMEURI=true

for BASEURI in $(grep -vE "^#|^$|^https" "$BASEFOLDER/${BASENAME%.*}.in" | sed 's,^http://,,')
do
    BASEURI=${BASEURI%%/*}
    echo -e "\n=== $BASEURI ==="
    DSTFOLDER="$BASEFOLDER/downloaded/$BASEURI"
    mkdir -p "$DSTFOLDER" && \
    SAMEURI=true
    while $SAMEURI
    do
        echo -n "Grab photos of '$BASEURI' before $(date -d @${BEFORE##*=} +%x) ? [Yn] "
        read moar
        [[ "$(echo "$moar" | tr [:upper:] [:lower:])" = "n" ]] && SAMEURI=false && continue
        next_page
        BEFORE=$(curl -H "Accept-Encoding: gzip" -s "http://$BASEURI/${BEFORE#/}" | gunzip | grep next_page_link | sed -r 's,.*href="([^""]*)".*,\1,')
    done
done
