#!/usr/bin/env bash



CONNECTORS_DIR="cos-fleet-catalog-camel"

cat /dev/null > "kustomization.yaml"

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