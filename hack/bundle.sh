#!/usr/bin/env bash

if [[ ! "$#" -gt 1 ]]; then
    echo "Missing overlay name" >&2
    exit 2
fi

for env_var in ADDON_VERSION ADDON_OVERLAY; do
  if [ -z "${!env_var}" ]; then
    echo "Make sure to set the ${env_var} environment variable." >&2
    exit 2
  fi
done

export BUNDLE_ID="${1}"
export BUNDLE_DIR="${2}"
export BUNDLE_BASE=$(dirname "${BASH_SOURCE[0]}")/..
export DIR_OVERLAY="${BUNDLE_BASE}/kustomize/overlays/${ADDON_OVERLAY}/${BUNDLE_ID}"
export DIR_ADDON="${BUNDLE_BASE}/addons/connectors-operator/${BUNDLE_DIR}"

if [ ! -d "${DIR_OVERLAY}" ]; then
    echo "Missing overlay ${DIR_OVERLAY}" >&2
    exit 2
fi

echo "##############################################"
echo "# id      : ${BUNDLE_ID}"
echo "# version : ${ADDON_VERSION}"
echo "# dir     : ${BUNDLE_DIR}"
echo "# base    : ${BUNDLE_BASE}"
echo "##############################################"

kustomize build "${DIR_OVERLAY}" | operator-sdk generate bundle \
    --kustomize-dir "${DIR_ADDON}/bases"  \
    --package "${BUNDLE_ID}" \
    --channels stable \
    --default-channel stable \
    --output-dir "${DIR_ADDON}" \
    --version "${ADDON_VERSION}"

rm bundle.Dockerfile

yq -i 'del(.annotations."operators.operatorframework.io.metrics.builder")' \
  "${DIR_ADDON}/metadata/annotations.yaml"
yq -i 'del(.annotations."operators.operatorframework.io.metrics.mediatype.v1")' \
  "${DIR_ADDON}/metadata/annotations.yaml"
yq -i 'del(.annotations."operators.operatorframework.io.metrics.project_layout")' \
  "${DIR_ADDON}/metadata/annotations.yaml"
yq -i 'del(.annotations."operators.operatorframework.io.test.mediatype.v1")' \
  "${DIR_ADDON}/metadata/annotations.yaml"
yq -i 'del(.annotations."operators.operatorframework.io.test.config.v1")' \
  "${DIR_ADDON}/metadata/annotations.yaml"