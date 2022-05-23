MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_PATH := $(patsubst %/,%,$(dir $(MKFILE_PATH)))
LOCAL_BIN_PATH := ${PROJECT_PATH}/bin

ADDON_PATH := ${PROJECT_PATH}/addons/connectors-operator

STRIMZI_BUNDLE_NAME  := strimzi-kafka-operator
CAMEL_K_BUNDLE_NAME  := camel-k-operator
CAMEL_BUNDLE_NAME 	 := cos-fleetshard-operator-camel
DEBEZIUM_BUNDLE_NAME := cos-fleetshard-operator-debezium
SYNC_BUNDLE_NAME 	 := cos-fleetshard-sync

OPERATOR_SDK_VERSION := v1.17.0

PREVIOUS_TAG := $(shell ./hack/fetch-previous-tag.sh)

export PATH := ${LOCAL_BIN_PATH}:$(PATH)

bundles: bundle/camel-k bundle/strimzi bundle/cos-fleetshard-sync bundle/cos-fleetshard-operator-camel bundle/cos-fleetshard-operator-debezium

#
# bundles
#

bundle/camel-k: operator-sdk
	./hack/bundle.sh \
		"camel-k" \
		"$(CAMEL_K_BUNDLE_NAME)" \
		"$(CAMEL_K_BUNDLE_NAME)/$(ADDON_VERSION)" \
		"stable"

bundle/strimzi: operator-sdk
	./hack/bundle.sh \
		"strimzi" \
		"$(STRIMZI_BUNDLE_NAME)" \
		"$(STRIMZI_BUNDLE_NAME)/$(ADDON_VERSION)" \
		"alpha"

bundle/cos-fleetshard-operator-camel: operator-sdk
	./hack/bundle.sh \
		"$(CAMEL_BUNDLE_NAME)" \
		"$(CAMEL_BUNDLE_NAME)" \
		"$(CAMEL_BUNDLE_NAME)/$(ADDON_VERSION)" \
		"stable"
		
	cp hack/templates/operator-dependencies.yaml \
		$(ADDON_PATH)/cos-fleetshard-operator-camel/$(ADDON_VERSION)/metadata/dependencies.yaml
	
	yq -i '.dependencies[0].value.packageName="$(CAMEL_K_BUNDLE_NAME)"' \
		$(ADDON_PATH)/cos-fleetshard-operator-camel/$(ADDON_VERSION)/metadata/dependencies.yaml
	yq -i '.dependencies[0].value.version=strenv(ADDON_VERSION)' \
		$(ADDON_PATH)/cos-fleetshard-operator-camel/$(ADDON_VERSION)/metadata/dependencies.yaml

	yq -i 'del(.status)' \
		$(ADDON_PATH)/cos-fleetshard-operator-camel/$(ADDON_VERSION)/manifests/cos-fleetshard-operator-camel_v1_service.yaml
		
	yq -i '.spec.replaces="$(CAMEL_BUNDLE_NAME).$(PREVIOUS_TAG)"' \
			$(ADDON_PATH)/cos-fleetshard-operator-camel/$(ADDON_VERSION)/manifests/cos-fleetshard-operator-camel.clusterserviceversion.yaml

bundle/cos-fleetshard-operator-debezium: operator-sdk
	./hack/bundle.sh \
		"$(DEBEZIUM_BUNDLE_NAME)" \
		"$(DEBEZIUM_BUNDLE_NAME)" \
		"$(DEBEZIUM_BUNDLE_NAME)/$(ADDON_VERSION)" \
		"stable"

	cp hack/templates/operator-dependencies.yaml \
		$(ADDON_PATH)/cos-fleetshard-operator-debezium/$(ADDON_VERSION)/metadata/dependencies.yaml

	yq -i '.dependencies[0].value.packageName="$(STRIMZI_BUNDLE_NAME)"' \
		$(ADDON_PATH)/cos-fleetshard-operator-debezium/$(ADDON_VERSION)/metadata/dependencies.yaml
	yq -i '.dependencies[0].value.version=strenv(ADDON_VERSION)' \
		$(ADDON_PATH)/cos-fleetshard-operator-debezium/$(ADDON_VERSION)/metadata/dependencies.yaml

	yq -i 'del(.status)' \
		$(ADDON_PATH)/cos-fleetshard-operator-debezium/$(ADDON_VERSION)/manifests/cos-fleetshard-operator-debezium_v1_service.yaml

	yq -i '.spec.replaces="$(DEBEZIUM_BUNDLE_NAME).$(PREVIOUS_TAG)"' \
			$(ADDON_PATH)/cos-fleetshard-operator-debezium/$(ADDON_VERSION)/manifests/cos-fleetshard-operator-debezium.clusterserviceversion.yaml

bundle/cos-fleetshard-sync: operator-sdk
	./hack/bundle.sh \
		"$(SYNC_BUNDLE_NAME)" \
		"$(SYNC_BUNDLE_NAME)" \
		main/$(ADDON_VERSION) \
		"stable"

	cp hack/templates/config.yaml \
		$(ADDON_PATH)/main
	cp hack/templates/main-dependencies.yaml \
		$(ADDON_PATH)/main/$(ADDON_VERSION)/metadata/dependencies.yaml

	yq -i '.dependencies[0].value.version=strenv(ADDON_VERSION)' \
		$(ADDON_PATH)/main/$(ADDON_VERSION)/metadata/dependencies.yaml
	yq -i '.dependencies[1].value.version=strenv(ADDON_VERSION)' \
		$(ADDON_PATH)/main/$(ADDON_VERSION)/metadata/dependencies.yaml

	yq -i 'del(.status)' \
		$(ADDON_PATH)/main/$(ADDON_VERSION)/manifests/cos-fleetshard-sync_v1_service.yaml

	yq -i '.spec.replaces="$(SYNC_BUNDLE_NAME).$(PREVIOUS_TAG)"' \
			$(ADDON_PATH)/main/$(ADDON_VERSION)/manifests/cos-fleetshard-sync.clusterserviceversion.yaml

#
# Helpers
#

operator-sdk:
ifeq (, $(shell command -v operator-sdk 2> /dev/null))
	@{ \
	set -e ;\
	if [ "$(shell uname -s 2>/dev/null || echo Unknown)" == "Darwin" ] ; then \
		curl \
			-L https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk_darwin_amd64 \
			-o operator-sdk ; \
	else \
		curl \
			-L https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk_linux_amd64 \
			-o operator-sdk ; \
	fi ;\
	chmod +x operator-sdk ;\
	mv operator-sdk $(LOCAL_BIN_PATH)/ ;\
	}
endif

#
# Helpers
#

.PHONY: bundle/init
.PHONY: bundle/camel-k 
.PHONY: bundle/strimzi
.PHONY: cos-fleetshard-sync
.PHONY: cos-fleetshard-operator-camel
.PHONY: cos-fleetshard-operator-debezium
.PHONY: operator-sdk