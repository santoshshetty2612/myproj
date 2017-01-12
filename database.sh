#!/bin/sh

CDN_ROOT="https://s3-eu-west-1.amazonaws.com/consult.univadis.com/delivery-consult"
JQ="jq-osx-amd64"
ENVIRONMENT="dev"

function get_cdn {
    if [ -z "${2}" ]; then
        DEST="-O"
   # else
    #    DEST="-o Consult/Consult/Resources/Resources${LANGUAGE}/Databases/${2}"
    #fi
    STATUS=$(curl -w "%{http_code}" ${DEST} "${CDN_ROOT}/${CODE}/${ENVIRONMENT}/${1}")
    if [ "${STATUS}" -ne "200" ]; then
       echo "could not get ${1}"
       exit 1
    fi
}

cd "$( dirname "${BASH_SOURCE[0]}" )/.."

if [ -n "${1}" ]; then
    LANGUAGES="${1}"
else
    LANGUAGES="FR UK US"
fi

for LANGUAGE in ${LANGUAGES}; do
    CODE=$(echo ${LANGUAGE} | tr '[:upper:]' '[:lower:]')
    get_cdn "manifest-db.json"

    if [ -n "${2}" ]; then
        DATABASES="${2}"
    else
        DATABASES=$(${JQ} -r 'keys[]' manifest-build-ios.json)
    fi

    echo "$DATABASES" | while read -r db; do
        schema=$(${JQ} -r ".${db}.schema" manifest-db.json)
        version=$(${JQ} -r ".${db}.version" manifest-db.json)
        DIR=$(echo ${db} | tr '[:upper:]' '[:lower:]')
        get_cdn "${DIR}/s${schema}/v${version}/coredata/Consult${db}.sqlite" "Consult${db}.sqlite"

    done

    rm -f manifest-db.json
done
