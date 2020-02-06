#!/bin/bash -eu


#        --tune-inotify \
#        --ensure-kubectl \
#        --kubernetes-version v1.14.6 \
#        --start-docker \

#~/go/src/github.com/kyma-project/test-infra
KYMA_DIR=/Users/i326884/go/src/github.com/kyma-project/kyma
./kind-install-kyma.sh
        --update-hosts \
        --delete-cluster \
        --kyma-sources "${KYMA_DIR}"\
        --kyma-overrides "${KYMA_DIR}/installation/resources/installer-config-local.yaml.tpl" \
        --kyma-installer "${KYMA_DIR}/installation/resources/installer-local.yaml" \
        --kyma-installation-cr "${KYMA_DIR}/installation/resources/installer-cr.yaml.tpl" \
        --kyma-installation-timeout 30m
