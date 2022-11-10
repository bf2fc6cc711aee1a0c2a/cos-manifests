#!/usr/bin/env bash


DIR=$(dirname "${BASH_SOURCE[0]}")
CONNECTORS_DIR="${DIR}/cos-fleet-catalog-camel"

cat /dev/null > "${DIR}/kustomization.yaml"

for D in "${CONNECTORS_DIR}"/*; do

    if [ -d ${D} ]; then
        CM_NAME=$(basename "${D}")

        echo "${D}"
        echo "${CM_NAME}"

        kustomize edit add configmap "${CM_NAME}" \
            --disableNameSuffixHash \
            --from-file="${D}"/*
    fi
done