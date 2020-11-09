#!/usr/bin/env bash

#Description: Adds new type "A" DNS entry for given subdomain and IP Address
#
#Expected vars:
# - CLOUDSDK_CORE_PROJECT: name of a GCP project where new DNS record is created.
# - CLOUDSDK_DNS_ZONE_NAME: Name of an existing DNS zone in the project (NOT its DNS name!)
# - DNS_FULL_NAME: DNS name
# - IP_ADDRESS: v4 IP Address for the DNS record.
#
#Permissions: In order to run this script you need to use a service account with "DNS Administrator" role

set -o errexit

SCRIPTS_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.."
#shellcheck source=prow/scripts/lib/log.sh
source "${SCRIPTS_PATH}/lib/log.sh"

discoverUnsetVar=false

for var in CLOUDSDK_DNS_ZONE_NAME DNS_FULL_NAME IP_ADDRESS; do
    if [ -z "${!var}" ] ; then
        echo "ERROR: $var is not set"
        discoverUnsetVar=true
    fi
done

if [ "${discoverUnsetVar}" = true ] ; then
    exit 1
fi


function createDNS() {
    set -x

    aws route53 change-resource-record-sets --hosted-zone-id "${CLOUDSDK_DNS_ZONE_NAME}" \
    --change-batch '{ "Comment": "Creating a record set","Changes": [ { "Action": "CREATE", "ResourceRecordSet": { "Name":"'"${DNS_FULL_NAME}"'", "Type": "A", "TTL":60, "ResourceRecords": [ { "Value": "'"${IP_ADDRESS}"'" } ] } } ] }'

    set +x
}

createDNS

SECONDS=0
END_TIME=$((SECONDS+600)) #600 seconds == 10 minutes

while [ ${SECONDS} -lt ${END_TIME} ];do
    echo "Trying to resolve ${DNS_FULL_NAME}"
    sleep 10

    RESOLVED_IP_ADDRESS=$(dig +short "${DNS_FULL_NAME}")

    if [ "${RESOLVED_IP_ADDRESS}" = "${IP_ADDRESS}" ]; then
        echo "Successfully resolved ${DNS_FULL_NAME} to ${RESOLVED_IP_ADDRESS}"
        exit 0
    fi
done

echo "Cannot resolve ${DNS_FULL_NAME} to expected IP_ADDRESS: ${IP_ADDRESS}."
exit 1
