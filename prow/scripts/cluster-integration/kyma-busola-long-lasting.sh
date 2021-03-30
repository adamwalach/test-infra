#!/usr/bin/env bash

set -e

#Description: Kyma CLI Integration plan on Gardener. This scripts implements a pipeline that consists of many steps. The purpose is to install and test Kyma using the CLI on a real Gardener cluster.
#
#Expected common vars:
# - JOB_TYPE - set up by prow (presubmit, postsubmit, periodic)
# - KYMA_PROJECT_DIR - directory path with Kyma sources to use for installation
# - GARDENER_REGION - Gardener compute region
# - GARDENER_ZONES - Gardener compute zones inside the region
# - GARDENER_CLUSTER_VERSION - Version of the Kubernetes cluster
# - GARDENER_KYMA_PROW_KUBECONFIG - Kubeconfig of the Gardener service account
# - GARDENER_KYMA_PROW_PROJECT_NAME - Name of the gardener project where the cluster will be integrated.
# - GARDENER_KYMA_PROW_PROVIDER_SECRET_NAME - Name of the secret configured in the gardener project to access the cloud provider
# - MACHINE_TYPE - (optional) machine type
#
#Please look in each provider script for provider specific requirements


function delete_cluster(){
    local name="$1"
    set +e
    kubectl annotate shoot "${name}" confirmation.gardener.cloud/deletion=true --overwrite
    kubectl delete   shoot "${name}" --wait=true
    set -e
}

function provisionBusola(){
    RESOURCES_PATH=${TEST_INFRA_SOURCES_DIR}/prow/scripts/resources/busola/

    export DOMAIN_NAME=$1

    log::info "We will install Busola on the cluster: ${DOMAIN_NAME}"
    # We create the cluster
    cat ${RESOURCES_PATH}/cluster-busola.yaml | envsubst | kubectl create -f -

    # #we wait for the cluster to be ready
    kubectl wait --for condition="ControlPlaneHealthy" --timeout=10m shoot "${DOMAIN_NAME}"

    # #we switch to the new cluster
    kubectl get secrets "${DOMAIN_NAME}.kubeconfig" -o jsonpath={.data.kubeconfig} | base64 -d > "${RESOURCES_PATH}/kubeconfig--busola--${DOMAIN_NAME}.yaml"
    export KUBECONFIG="${RESOURCES_PATH}/kubeconfig--busola--$DOMAIN_NAME.yaml"

    # # we ask for new certificates
    cat "${RESOURCES_PATH}/wildcardCert.yaml" | envsubst | kubectl apply -f -

    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    cat "${RESOURCES_PATH}/nginxValues.yaml" | envsubst | helm install ingress-nginx --namespace=kube-system -f - ingress-nginx/ingress-nginx

    #wait for ingress controller to start
    kubectl wait --namespace kube-system \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s

    #install busola
    FULL_DOMAIN="${DOMAIN_NAME}.${GARDENER_KYMA_PROW_PROJECT_NAME}.shoot.canary.k8s-hana.ondemand.com"

    find "${BUSOLA_SOURCES_DIR}/resources" -name "*.yaml" \
         -exec sed -i "s/%DOMAIN%/${FULL_DOMAIN}/g" "{}" \;

    kubectl apply -k "${BUSOLA_SOURCES_DIR}/resources"

    TERM=dumb kubectl cluster-info
    echo "Please generate params for using k8s http://enkode.surge.sh/"
    echo "Kyma busola Url:"
    echo "https://busola.${DOMAIN_NAME}.${GARDENER_KYMA_PROW_PROJECT_NAME}.shoot.canary.k8s-hana.ondemand.com?auth=generated_params_in_previous_step"
}

ENABLE_TEST_LOG_COLLECTOR=false

export TEST_INFRA_SOURCES_DIR="${KYMA_PROJECT_DIR}/test-infra"
export BUSOLA_SOURCES_DIR="${KYMA_PROJECT_DIR}/busola"
export KYMA_SOURCES_DIR="${KYMA_PROJECT_DIR}/kyma"
export TEST_INFRA_CLUSTER_INTEGRATION_SCRIPTS="${TEST_INFRA_SOURCES_DIR}/prow/scripts/cluster-integration/helpers"

# shellcheck source=prow/scripts/lib/log.sh
source "${TEST_INFRA_SOURCES_DIR}/prow/scripts/lib/log.sh"
# shellcheck source=prow/scripts/lib/utils.sh
source "${TEST_INFRA_SOURCES_DIR}/prow/scripts/lib/utils.sh"
# shellcheck source=prow/scripts/lib/kyma.sh
source "${TEST_INFRA_SOURCES_DIR}/prow/scripts/lib/kyma.sh"

# All provides require these values, each of them may check for additional variables
requiredVars=(
    GARDENER_PROVIDER
    KYMA_PROJECT_DIR
    GARDENER_REGION
    GARDENER_ZONES
    GARDENER_CLUSTER_VERSION
    GARDENER_KYMA_PROW_KUBECONFIG
    GARDENER_KYMA_PROW_PROJECT_NAME
    GARDENER_KYMA_PROW_PROVIDER_SECRET_NAME
)

utils::check_required_vars "${requiredVars[@]}"

if [[ $GARDENER_PROVIDER == "gcp" ]]; then
    # shellcheck source=prow/scripts/lib/gardener/gcp.sh
    #source "${TEST_INFRA_SOURCES_DIR}/prow/scripts/lib/gardener/gcp.sh"
    log::info "Provisioning on gcp"
else
    ## TODO what should I put here? Is this a backend?
    log::error "GARDENER_PROVIDER ${GARDENER_PROVIDER} is not yet supported"
    exit 1
fi

readonly COMMON_NAME_PREFIX="grd"
readonly KYMA_NAME_SUFFIX="kyma"
readonly BUSOLA_NAME_SUFFIX="busol"

export KUBECONFIG="${GARDENER_KYMA_PROW_KUBECONFIG}"

KYMA_COMMON_NAME=$(echo "${COMMON_NAME_PREFIX}${KYMA_NAME_SUFFIX}" | tr "[:upper:]" "[:lower:]")
BUSOLA_COMMON_NAME=$(echo "${COMMON_NAME_PREFIX}${BUSOLA_NAME_SUFFIX}" | tr "[:upper:]" "[:lower:]")
export KYMA_COMMON_NAME
export BUSOLA_COMMON_NAME

log::info "Kyma cluster name: ${KYMA_COMMON_NAME}"
log::info "Busola cluster name: ${BUSOLA_COMMON_NAME}"


#${TEST_INFRA_SOURCES_DIR}/prow/scripts/cluster-integration/busola/installKymaNew.sh "master" ${KYMA_COMMON_NAME}
delete_cluster "${BUSOLA_COMMON_NAME}"
provisionBusola "${BUSOLA_COMMON_NAME}"
#${TEST_INFRA_SOURCES_DIR}/prow/scripts/cluster-integration/busola/installBusola.sh ${BUSOLA_COMMON_NAME}
